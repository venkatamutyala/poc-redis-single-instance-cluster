# poc-redis-single-instance-cluster



# Directions

- Create 2 terminals
- In one terminal run `./setup.sh`
- In the second terminal run `./test.sh`
- Examine outputs in each terminal




The commands above should match the screenshots below:

`./setup.sh`
<img width="1184" height="605" alt="image" src="https://github.com/user-attachments/assets/7416a943-5c2f-4c24-860d-e7d246f695dc" />

`./test.sh`
<img width="662" height="311" alt="image" src="https://github.com/user-attachments/assets/98ad4edc-b45d-46e0-9882-5720574513db" />

## Environment variables 🔧

### Required
- **AWS_REGION** — AWS region used for ECR (e.g., `us-east-1`). The Makefile exits if not set.
- **REPO_NAME** — ECR repository name (e.g., `dev-redis`). The Makefile exits if not set.
- **AWS credentials** — credentials must be available for the AWS CLI to retrieve account info and login. Provide via `aws configure` or environment variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN` (if applicable)

### Optional
- **VERSION** — when set (e.g., `1.2.3`), `make push` will tag and push a versioned image in addition to `latest`.
- **REDIS_PASS** — password used by `make test` (defaults to `my-secret-password`).
- **TAG** — image tag (defaults to `latest`), can be overridden by exporting `TAG` or passing `TAG=...` to `make`.

### Quick usage 💡
```bash
export AWS_REGION=us-east-1
export REPO_NAME=dev-redis
export VERSION=1.2.3    # optional
export REDIS_PASS=supersecret  # optional for tests

make info
make push
```

> Note: `make push` runs `login` automatically; ensure your AWS session/credentials are valid or `aws sts` will fail.
