# Spec 006 — AWS Infrastructure

**Depends on:** Spec 005  
**Last Updated:** 2026-04-10  

---

## Overview

Provision and configure the AWS infrastructure: S3+CloudFront for static hosting, API Gateway + Lambda for matchmaking, DynamoDB for persistence, ElastiCache for room state, ECS Fargate for game servers, and the CI/CD pipeline. Full infrastructure-as-code in Terraform.

---

## Requirements

### REQ-006-001: Infrastructure Repository Layout
Create the `infra/` directory with this structure:

```
infra/
├── terraform/
│   ├── main.tf                # Top-level module composition
│   ├── variables.tf           # All input variables
│   ├── outputs.tf             # Important resource ARNs/URLs
│   ├── providers.tf           # AWS provider config
│   ├── backend.tf             # S3 backend for state
│   ├── modules/
│   │   ├── hosting/           # S3 + CloudFront
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── api/               # API Gateway + Lambda IAM roles
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── data/              # DynamoDB + ElastiCache
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── gameserver/        # ECS + ECR + ALB
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── networking/        # VPC + subnets + security groups
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── dev.tfvars
│       └── prod.tfvars
├── lambda/
│   ├── shared/                # Shared utilities
│   │   ├── auth.js
│   │   └── dynamo.js
│   ├── matchmaking/
│   │   ├── index.js
│   │   ├── package.json
│   │   └── package-lock.json
│   ├── auth/
│   │   ├── index.js
│   │   └── package.json
│   ├── player/
│   │   ├── index.js
│   │   └── package.json
│   ├── leaderboard/
│   │   ├── index.js
│   │   └── package.json
│   └── room-cleanup/
│       ├── index.js           # Scales down ECS when rooms empty
│       └── package.json
├── docker/
│   └── gameserver/
│       ├── Dockerfile
│       └── start.sh
└── scripts/
    ├── deploy.sh              # Full deploy script
    ├── export-web.sh          # Godot web export
    └── export-server.sh       # Godot server export
```

### REQ-006-002: Networking Module
VPC setup optimized for cost (minimal NAT Gateway usage):

```hcl
# infra/terraform/modules/networking/main.tf

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr   # "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "little-six-${var.env}" }
}

# Public subnets (ECS tasks with public IPs — avoids NAT Gateway cost)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "little-six-public-${count.index}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# No NAT Gateway (saves ~$32/month) — ECS tasks use public subnets
# Lambda functions use VPC-less configuration for DynamoDB/Redis access
# (DynamoDB accessed via endpoint, Redis via VPC peering if needed)
```

**Cost optimization:** ECS Fargate tasks run in public subnets with public IPs. This eliminates the need for a NAT Gateway ($32/month savings). Lambda functions are NOT in the VPC to avoid ENI allocation delays (Lambda cold starts are slower in VPC). Redis is accessed via a VPC endpoint.

### REQ-006-003: Hosting Module (S3 + CloudFront)

```hcl
# infra/terraform/modules/hosting/main.tf

resource "aws_s3_bucket" "game" {
  bucket = "little-six-game-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "game" {
  bucket                  = aws_s3_bucket.game.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "game" {
  name                              = "little-six-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "game" {
  name = "little-six-coop-coep"

  custom_headers_config {
    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin"
      override = true
    }
    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "require-corp"
      override = true
    }
  }

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; connect-src 'self' wss://*.littlesix.gg https://api.littlesix.gg; worker-src 'self' blob:;"
      override                = true
    }
  }
}

resource "aws_cloudfront_distribution" "game" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["littlesix.gg", "www.littlesix.gg"]

  origin {
    domain_name              = aws_s3_bucket.game.bucket_regional_domain_name
    origin_id                = "S3"
    origin_access_control_id = aws_cloudfront_origin_access_control.game.id
  }

  # Godot WASM/JS files — long cache (versioned filenames)
  ordered_cache_behavior {
    path_pattern           = "*.wasm"
    allowed_methods        = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.game.id
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
  }

  default_cache_behavior {
    allowed_methods             = ["GET", "HEAD"]
    cached_methods              = ["GET", "HEAD"]
    target_origin_id            = "S3"
    viewer_protocol_policy      = "redirect-to-https"
    compress                    = true
    response_headers_policy_id  = aws_cloudfront_response_headers_policy.game.id
    # index.html: no-cache (always fresh)
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}
```

### REQ-006-004: Data Module (DynamoDB + ElastiCache)

**DynamoDB Tables:**

| Table | PK | SK | Purpose |
|---|---|---|---|
| `little-six-players` | `player_id` | — | Player data, racer stats |
| `little-six-races` | `race_id` | `timestamp` | Race history (TTL 90 days) |
| `little-six-leaderboard` | `season_id` | `elo_rating` | Season rankings (GSI on player_id) |

**ElastiCache:**
- Engine: Redis 7.x
- Node type: `cache.t3.micro` (~$13/month)
- Purpose: Active room state (fast reads for matchmaking), rate limiting
- TTL on room keys: 1 hour

```hcl
resource "aws_elasticache_cluster" "rooms" {
  cluster_id           = "little-six-rooms-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
}
```

### REQ-006-005: API Gateway + Lambda Module

**API Routes:**

```
POST /api/auth/guest                → lambda:auth:createGuest
GET  /api/match?type=&room_code=   → lambda:matchmaking:findMatch
POST /api/rooms/{id}/ready         → lambda:matchmaking:serverReady (server→lambda)
POST /api/player/save              → lambda:player:saveData
GET  /api/player/{id}              → lambda:player:getData
GET  /api/leaderboard?season=      → lambda:leaderboard:get
```

All Lambda functions use Node.js 20 runtime, 256MB memory, 10s timeout.

**Auth Lambda** (`POST /api/auth/guest`):
```javascript
// Creates anonymous player account, returns JWT
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');

exports.handler = async (event) => {
    const playerId = 'guest_' + uuidv4();
    const token = jwt.sign({ player_id: playerId }, process.env.JWT_SECRET, { expiresIn: '30d' });
    
    await db.send(new PutItemCommand({
        TableName: process.env.PLAYERS_TABLE,
        Item: {
            player_id: { S: playerId },
            is_guest: { BOOL: true },
            created_at: { N: String(Date.now()) },
            expires_at: { N: String(Math.floor(Date.now()/1000) + 90*86400) }, // 90-day TTL
        },
        ConditionExpression: 'attribute_not_exists(player_id)',
    }));
    
    return {
        statusCode: 200,
        body: JSON.stringify({ player_id: playerId, token }),
    };
};
```

**Room Cleanup Lambda** (EventBridge schedule, every 5 minutes):
```javascript
// Checks Redis for rooms with 0 active players, scales down ECS
exports.handler = async () => {
    const activeRooms = await redis.keys('room:*');
    const ecsClient = new ECSClient({});
    
    let activeCount = 0;
    for (const key of activeRooms) {
        const room = JSON.parse(await redis.get(key));
        if (room.state !== 'CLEANUP' && room.player_count > 0) {
            activeCount++;
        }
    }
    
    // Scale ECS desired count to match active rooms
    await ecsClient.send(new UpdateServiceCommand({
        cluster: process.env.ECS_CLUSTER,
        service: process.env.ECS_SERVICE,
        desiredCount: Math.max(0, activeCount),
    }));
};
```

### REQ-006-006: ECS Game Server Module

**ECR Repository:**
```hcl
resource "aws_ecr_repository" "gameserver" {
  name                 = "little-six-gameserver"
  image_tag_mutability = "MUTABLE"

  lifecycle_policy {
    policy = jsonencode({
      rules = [{
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }]
    })
  }
}
```

**ECS Service (scale-to-zero approach):**
```hcl
resource "aws_ecs_service" "gameserver" {
  name            = "little-six-gameserver"
  cluster         = aws_ecs_cluster.game.id
  task_definition = aws_ecs_task_definition.gameserver.arn
  desired_count   = 0   # Starts at 0; Lambda scales up per room

  # Fargate Spot for cost reduction
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.gameserver.id]
    assign_public_ip = true  # No NAT Gateway needed
  }

  # No load balancer — each task gets its own public IP
  # ALB routes to tasks via registered IPs
}
```

**Per-room task launch** (from Matchmaking Lambda):
```javascript
// Launch one ECS task per room
const task = await ecs.send(new RunTaskCommand({
    cluster: process.env.ECS_CLUSTER,
    taskDefinition: process.env.ECS_TASK_DEF,
    count: 1,
    launchType: 'FARGATE',
    capacityProviderStrategy: [{ capacityProvider: 'FARGATE_SPOT', weight: 100 }],
    networkConfiguration: {
        awsvpcConfiguration: {
            subnets: process.env.SUBNET_IDS.split(','),
            securityGroups: [process.env.SG_ID],
            assignPublicIp: 'ENABLED',
        },
    },
    overrides: {
        containerOverrides: [{
            name: 'gameserver',
            environment: [
                { name: 'ROOM_ID', value: roomId },
                { name: 'JWT_SECRET', value: process.env.JWT_SECRET },
            ],
        }],
    },
}));

// Store task ARN + public IP in Redis room entry
// The task, on startup, calls POST /api/rooms/{id}/ready with its public IP
```

### REQ-006-007: CI/CD GitHub Actions

Create `.github/workflows/deploy.yml` — see AWS Deployment doc for full YAML.

**Workflow triggers:**
- Push to `main` → deploy to dev environment
- Push to `release/**` → deploy to prod environment
- Manual dispatch → deploy to specified environment

**Steps:**
1. Install Godot 4.6 + export templates (download from Godot releases)
2. Export web build → `dist/web/`
3. Export Linux server build → `dist/server/`
4. Run Godot unit tests (if test runner configured)
5. Upload web build to S3 (versioned path: `s3://little-six-game-{env}/web/`)
6. Build Docker image for server binary
7. Push image to ECR
8. Register new ECS task definition revision
9. Invalidate CloudFront cache for `index.html`

**Required secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION (us-east-1)
ECR_REGISTRY
CF_DISTRIBUTION_ID
JWT_SECRET
```

### REQ-006-008: Local Development Environment
Create a Docker Compose file for local dev:

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  matchmaking:
    build: ./infra/lambda/matchmaking
    ports: ["3000:3000"]
    environment:
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=dev_secret_not_for_prod
      - DYNAMODB_TABLE_PLAYERS=little-six-players-dev
      - AWS_REGION=us-east-1
      - AWS_ACCESS_KEY_ID=test
      - AWS_SECRET_ACCESS_KEY=test
      - DYNAMODB_ENDPOINT=http://dynamodb-local:8000
    depends_on: [redis, dynamodb-local]

  dynamodb-local:
    image: amazon/dynamodb-local:latest
    ports: ["8000:8000"]

  game-server:
    build: ./infra/docker/gameserver
    ports: ["7777:7777"]
    environment:
      - ROOM_ID=LOCAL
      - JWT_SECRET=dev_secret_not_for_prod
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./dist/server:/game
    depends_on: [redis]
```

---

## Acceptance Criteria

- [ ] `terraform plan` runs without errors for both dev and prod environments
- [ ] `terraform apply` creates all resources
- [ ] S3 bucket created with correct bucket policy (CloudFront OAC only)
- [ ] CloudFront distribution returns COOP/COEP headers on all responses
- [ ] CloudFront serves Godot web export files correctly
- [ ] Lambda functions deploy and return 200 for health check GETs
- [ ] `POST /api/auth/guest` returns `{ player_id, token }` in < 500ms
- [ ] `GET /api/match?type=quick` returns `{ server_url, room_id, join_token }` in < 2s
- [ ] DynamoDB tables created with correct key schemas
- [ ] ElastiCache Redis reachable from Lambda (if in VPC) or via endpoint
- [ ] ECR repository created
- [ ] ECS cluster created with Fargate Spot capacity
- [ ] `docker-compose up` starts local dev stack successfully
- [ ] Game client can connect to local dev game server
- [ ] GitHub Actions workflow runs successfully on push to main
- [ ] S3 web build updated after CI run
- [ ] CloudFront cache invalidated for index.html after deploy

---

## Cost Estimates

| Resource | Dev/Month | Prod/Month (idle) | Prod/Month (50 CCU) |
|---|---|---|---|
| S3 + CloudFront | ~$0.10 | ~$0.50 | ~$2.00 |
| API Gateway (HTTP) | ~$0.01 | ~$0.05 | ~$1.00 |
| Lambda | ~$0 | ~$0 | ~$0.50 |
| DynamoDB | ~$0.05 | ~$0.25 | ~$2.00 |
| ElastiCache t3.micro | ~$5.00 | ~$13.00 | ~$13.00 |
| ECS Fargate Spot | ~$0 | ~$0 | ~$20.00 |
| **Total** | **~$5** | **~$14** | **~$38** |

**Note:** ElastiCache is the dominant idle cost. Alternative for truly minimal cost: use DynamoDB instead of Redis for room state (higher latency but saves $13/month if traffic is very low).
