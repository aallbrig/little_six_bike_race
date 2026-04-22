# AWS Deployment Guide — Little Six

**Version:** 1.0  
**Status:** Approved for Implementation  
**Last Updated:** 2026-04-10  

---

## 1. Architecture Overview

```
                    ┌─────────────────────────────────────────┐
                    │           AWS Cloud (us-east-1)          │
                    │                                          │
Internet ──→  Route 53 (DNS)                                  │
                    │                                          │
         ┌──────────▼───────────────────────────────────┐     │
         │  CloudFront Distribution                      │     │
         │  - Origin 1: S3 (static game files)          │     │
         │  - Origin 2: ALB (WSS game server)           │     │
         │  - Origin 3: API Gateway (REST API)          │     │
         └──────────────────────────────────────────────┘     │
                    │                                          │
         ┌──────────▼───────────────────────────────────┐     │
         │  S3 Bucket: little-six-game                  │     │
         │  - /web/        (Godot web export)           │     │
         │  - /assets/     (CDN-cached assets)          │     │
         └──────────────────────────────────────────────┘     │
                    │                                          │
         ┌──────────▼───────────────────────────────────┐     │
         │  API Gateway (HTTP API)                       │     │
         │  POST /api/auth/guest                         │     │
         │  GET  /api/match                              │     │
         │  POST /api/player/save                        │     │
         │  GET  /api/leaderboard                        │     │
         └───────────┬──────────────────────────────────┘     │
                     │                                          │
         ┌───────────▼──────────────────────────────────┐     │
         │  Lambda Functions (Node.js 20)                │     │
         │  + ElastiCache Redis (room state)             │     │
         │  + DynamoDB tables                            │     │
         └──────────────────────────────────────────────┘     │
                    │                                          │
         ┌──────────▼───────────────────────────────────┐     │
         │  Application Load Balancer                    │     │
         │  (WebSocket upgrade supported)                │     │
         └───────────┬──────────────────────────────────┘     │
                     │                                          │
         ┌───────────▼──────────────────────────────────┐     │
         │  ECS Fargate (Spot capacity)                  │     │
         │  Service: little-six-gameserver               │     │
         │  Tasks: 0-N (auto-scaling)                    │     │
         │  Image: little-six-server:latest (ECR)        │     │
         └──────────────────────────────────────────────┘     │
                    └─────────────────────────────────────────┘
```

---

## 2. Infrastructure as Code (Terraform)

All infrastructure is defined in `infra/terraform/`. Deploy with:

```bash
cd infra/terraform
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

### 2.1 Directory Structure

```
infra/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── s3-cloudfront/   # Static hosting
│   │   ├── api-gateway/     # REST API
│   │   ├── lambda/          # Matchmaking functions
│   │   ├── ecs-gameserver/  # Game server tasks
│   │   ├── dynamodb/        # Tables
│   │   └── elasticache/     # Redis
│   └── environments/
│       ├── dev.tfvars
│       └── prod.tfvars
├── lambda/
│   ├── matchmaking/
│   │   ├── index.js
│   │   └── package.json
│   ├── auth/
│   │   ├── index.js
│   │   └── package.json
│   └── leaderboard/
│       ├── index.js
│       └── package.json
└── docker/
    └── gameserver/
        ├── Dockerfile
        └── start.sh
```

### 2.2 Key Resource Definitions

**S3 + CloudFront (simplified):**

```hcl
resource "aws_s3_bucket" "game_static" {
  bucket = "little-six-game-${var.environment}"
}

resource "aws_cloudfront_distribution" "game" {
  origin {
    domain_name = aws_s3_bucket.game_static.bucket_regional_domain_name
    origin_id   = "S3-game-static"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Cache behavior for Godot WASM files
  ordered_cache_behavior {
    path_pattern     = "*.wasm"
    allowed_methods  = ["GET", "HEAD"]
    compress         = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    
    # WASM files change with each build; use short TTL or versioned filenames
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # Required COOP/COEP headers for SharedArrayBuffer (needed by Godot web export)
  response_headers_policy_id = aws_cloudfront_response_headers_policy.game.id

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-game-static"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# CRITICAL: Godot web builds require these headers for SharedArrayBuffer
resource "aws_cloudfront_response_headers_policy" "game" {
  name = "little-six-game-headers"

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
}
```

**DynamoDB Tables:**

```hcl
resource "aws_dynamodb_table" "players" {
  name         = "little-six-players-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "player_id"

  attribute {
    name = "player_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = { Game = "LittleSix", Env = var.environment }
}

resource "aws_dynamodb_table" "races" {
  name         = "little-six-races-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "race_id"
  range_key    = "timestamp"

  attribute {
    name = "race_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true  # Auto-delete race records after 90 days
  }
}

resource "aws_dynamodb_table" "leaderboard" {
  name         = "little-six-leaderboard-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "season_id"
  range_key    = "elo_rating"

  attribute {
    name = "season_id"
    type = "S"
  }

  attribute {
    name = "elo_rating"
    type = "N"
  }
}
```

**ECS Fargate Game Server:**

```hcl
resource "aws_ecs_cluster" "game" {
  name = "little-six-${var.environment}"

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }
}

resource "aws_ecs_task_definition" "gameserver" {
  family                   = "little-six-gameserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"   # 0.5 vCPU
  memory                   = "1024"  # 1 GB

  container_definitions = jsonencode([{
    name  = "gameserver"
    image = "${aws_ecr_repository.gameserver.repository_url}:latest"
    
    portMappings = [{
      containerPort = 7777
      protocol      = "tcp"
    }]

    environment = [
      { name = "DYNAMODB_TABLE_RACES", value = aws_dynamodb_table.races.name },
      { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.rooms.cache_nodes[0].address}:6379" },
      { name = "MAX_PLAYERS", value = "6" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"  = "/ecs/little-six-gameserver"
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Auto-scaling: scale to zero when no active rooms
resource "aws_appautoscaling_target" "gameserver" {
  max_capacity       = 50   # 50 rooms max = 300 players
  min_capacity       = 0    # Scale to zero
  resource_id        = "service/${aws_ecs_cluster.game.name}/${aws_ecs_service.gameserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

---

## 3. Lambda Functions

### 3.1 Matchmaking Lambda

```javascript
// infra/lambda/matchmaking/index.js
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { ECSClient, RunTaskCommand } = require('@aws-sdk/client-ecs');
const redis = require('ioredis');
const jwt = require('jsonwebtoken');

const db = new DynamoDBClient({ region: process.env.AWS_REGION });
const ecs = new ECSClient({ region: process.env.AWS_REGION });
const redisClient = new redis(process.env.REDIS_URL);

exports.handler = async (event) => {
  const { type, room_code } = event.queryStringParameters || {};
  const playerId = event.requestContext.authorizer?.principalId || 'guest';

  let room = null;

  if (type === 'private' && room_code) {
    room = await findPrivateRoom(room_code);
    if (!room) return { statusCode: 404, body: JSON.stringify({ error: 'Room not found' }) };
  } else {
    // Find an open quick-race room
    room = await findOpenRoom(type || 'quick');
    if (!room) {
      // Create a new room
      room = await createRoom(type || 'quick');
      await startGameServerTask(room.room_id);
    }
  }

  // Reserve slot in room
  await reserveSlot(room.room_id, playerId);

  // Generate join token
  const token = jwt.sign(
    { player_id: playerId, room_id: room.room_id },
    process.env.JWT_SECRET,
    { expiresIn: '5m' }
  );

  return {
    statusCode: 200,
    body: JSON.stringify({
      server_url: room.server_url,
      room_id: room.room_id,
      join_token: token,
      player_count: room.player_count,
    }),
  };
};

async function createRoom(type) {
  const roomId = generateRoomCode();
  const serverUrl = `wss://game.littlesix.gg/room/${roomId}`;
  
  await redisClient.setex(`room:${roomId}`, 3600, JSON.stringify({
    room_id: roomId,
    type,
    state: 'WAITING',
    server_url: serverUrl,
    player_count: 0,
    max_players: 6,
    created_at: Date.now(),
  }));

  return { room_id: roomId, server_url: serverUrl, player_count: 0 };
}

async function startGameServerTask(roomId) {
  await ecs.send(new RunTaskCommand({
    cluster: process.env.ECS_CLUSTER,
    taskDefinition: process.env.ECS_TASK_DEF,
    launchType: 'FARGATE',
    networkConfiguration: {
      awsvpcConfiguration: {
        subnets: process.env.SUBNET_IDS.split(','),
        securityGroups: [process.env.SECURITY_GROUP_ID],
        assignPublicIp: 'ENABLED',
      },
    },
    overrides: {
      containerOverrides: [{
        name: 'gameserver',
        environment: [
          { name: 'ROOM_ID', value: roomId },
        ],
      }],
    },
  }));
}

function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}
```

---

## 4. Docker Image (Game Server)

```dockerfile
# infra/docker/gameserver/Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libgles2-mesa \
    libxrandr2 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /game
COPY dist/server/little_six_server .
COPY dist/server/little_six_server.pck .
COPY infra/docker/gameserver/start.sh .

RUN chmod +x little_six_server start.sh

EXPOSE 7777

ENTRYPOINT ["./start.sh"]
```

```bash
#!/bin/bash
# infra/docker/gameserver/start.sh
exec ./little_six_server \
  --headless \
  --room-id "${ROOM_ID}" \
  --port 7777 \
  --max-players "${MAX_PLAYERS:-6}" \
  --dynamodb-table "${DYNAMODB_TABLE_RACES}"
```

---

## 5. CI/CD Pipeline

### 5.1 GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]
  release:
    types: [created]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Godot
        run: |
          wget -q https://github.com/godotengine/godot/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip
          unzip -q Godot_v4.6-stable_linux.x86_64.zip
          mv Godot_v4.6-stable_linux.x86_64 /usr/local/bin/godot
          chmod +x /usr/local/bin/godot
      
      - name: Install Export Templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates/4.6.stable
          wget -q https://github.com/godotengine/godot/releases/download/4.6-stable/Godot_v4.6-stable_export_templates.tpz
          unzip -q Godot_v4.6-stable_export_templates.tpz -d templates/
          cp templates/templates/* ~/.local/share/godot/export_templates/4.6.stable/
      
      - name: Export Web Build
        run: |
          mkdir -p dist/web
          godot --headless --path godot/LittleSix \
            --export-release "Web" \
            dist/web/index.html
      
      - name: Upload to S3
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws s3 sync dist/web/ s3://little-six-game-prod/web/ \
            --cache-control "max-age=31536000,immutable" \
            --exclude "*.html" \
            --exclude "*.json"
          aws s3 cp dist/web/index.html s3://little-six-game-prod/web/index.html \
            --cache-control "no-cache"
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CF_DISTRIBUTION_ID }} \
            --paths "/web/*"

  build-server:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Export Linux Server
        run: |
          mkdir -p dist/server
          godot --headless --path godot/LittleSix \
            --export-release "Linux Server" \
            dist/server/little_six_server
      
      - name: Build Docker Image
        run: |
          docker build -f infra/docker/gameserver/Dockerfile \
            -t little-six-server:${{ github.sha }} .
      
      - name: Push to ECR
        env:
          AWS_DEFAULT_REGION: us-east-1
        run: |
          aws ecr get-login-password | docker login --username AWS \
            --password-stdin ${{ secrets.ECR_REGISTRY }}
          docker tag little-six-server:${{ github.sha }} \
            ${{ secrets.ECR_REGISTRY }}/little-six-server:latest
          docker push ${{ secrets.ECR_REGISTRY }}/little-six-server:latest
      
      - name: Update ECS Task Definition
        run: |
          aws ecs register-task-definition \
            --cli-input-json file://infra/terraform/ecs-task-def.json
```

---

## 6. Environment Configuration

### 6.1 Required Secrets (GitHub)

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key (least-privilege) |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `CF_DISTRIBUTION_ID` | CloudFront distribution ID |
| `ECR_REGISTRY` | ECR registry URL |
| `JWT_SECRET` | Secret for join token signing |

### 6.2 Lambda Environment Variables

| Variable | Description |
|---|---|
| `REDIS_URL` | ElastiCache Redis endpoint |
| `ECS_CLUSTER` | ECS cluster name |
| `ECS_TASK_DEF` | ECS task definition ARN |
| `SUBNET_IDS` | Comma-separated VPC subnet IDs |
| `SECURITY_GROUP_ID` | Security group for ECS tasks |
| `JWT_SECRET` | Must match game server's secret |
| `DYNAMODB_TABLE_PLAYERS` | Player table name |
| `DYNAMODB_TABLE_RACES` | Race history table name |

---

## 7. Cost Monitoring

### 7.1 AWS Budget Alerts

Set up budget alerts in AWS Console:
- Alert at $10/month (baseline warning)
- Alert at $50/month (moderate load)
- Alert at $200/month (investigate viralness!)

### 7.2 Cost Optimization Checklist

- [x] ECS uses Fargate **Spot** capacity (70% cheaper)
- [x] DynamoDB on-demand pricing (no idle cost)
- [x] Lambda free tier: 1M requests/month free
- [x] ElastiCache: t3.micro cache.t3.micro (~$13/month) — acceptable
- [x] CloudFront: first 1TB transfer free/month
- [x] S3: first 5GB free; game build ~100MB = negligible
- [x] ECS scale-to-zero when no active games
- [x] DynamoDB TTL on race records (auto-delete after 90 days)
- [x] CloudWatch log retention: 30 days

### 7.3 Scaling Trigger

Lambda automatically triggers new ECS task per room. When room closes (race ends or all players leave), the container exits naturally. ECS desired count scales down via a scheduled Lambda that checks Redis for active rooms every 5 minutes.

---

## 8. Local Development Setup

```bash
# 1. Install dependencies
npm install -g aws-sam-cli  # For Lambda local testing

# 2. Start local Redis
docker run -d -p 6379:6379 redis:7-alpine

# 3. Start matchmaking API locally
cd infra/lambda
sam local start-api --port 3000 --env-vars env.local.json

# 4. Run Godot game server locally
./godot_headless --headless \
  --path godot/LittleSix \
  --room-id LOCAL \
  --port 7777

# 5. Open game in browser (Godot web export dev server)
cd dist/web
python3 -m http.server 8080
# Visit http://localhost:8080
```

**Note:** Godot web exports require COOP/COEP headers for SharedArrayBuffer. Use the included `serve.py` which adds these headers, or use the SAM local setup which handles them.
