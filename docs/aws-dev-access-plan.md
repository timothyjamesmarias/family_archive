# Read-Only AWS Access for Development — Walkthrough

Creates an IAM user that can read the production bucket and nothing else,
and a local AWS CLI profile for it. Development uses it to show production
images (see `docs/prod-db-pull-plan.md`, part 3). About 10 minutes, all in
the AWS console plus two terminal commands.

Values used below (from the production CSP in `nixos-server/modules/traefik.nix`;
confirm on the S3 console's bucket list before starting):

- Bucket: `marias-family-archive`
- Region: `us-east-2`

## 1. Create the policy

1. Sign in at <https://console.aws.amazon.com> (root is fine for this).
2. Search bar → **IAM** → left sidebar **Policies** → **Create policy**.
3. In the policy editor switch to **JSON**, replace everything with:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "ListBucket",
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::marias-family-archive"
       },
       {
         "Sid": "ReadObjects",
         "Effect": "Allow",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::marias-family-archive/*"
       }
     ]
   }
   ```

   `GetObject` reads files. `ListBucket` lets the `aws s3 ls` check in step 5
   list keys, and makes a missing file answer "not found" instead of "access
   denied". The app doesn't strictly need it: Active Storage tracks variants
   in its own table rather than asking S3 whether a thumbnail exists.
   Neither permits any write; IAM denies everything not listed.
4. **Next**. Policy name: `family-archive-dev-readonly`. Description:
   `Development read-only access to the production artifacts bucket`.
5. **Create policy**.

## 2. Create the user

1. IAM sidebar → **Users** → **Create user**.
2. User name: `family-archive-dev`. Leave **Provide user access to the AWS
   Management Console** unchecked — it only needs keys. **Next**.
3. Permissions options: **Attach policies directly**. Search
   `family-archive-dev-readonly`, tick it. **Next**.
4. Review → **Create user**.

## 3. Create its access key

1. Click the new user `family-archive-dev` → **Security credentials** tab
   → **Access keys** → **Create access key**.
2. Use case: **Local code**. Tick the confirmation checkbox. **Next**.
3. Description tag: `laptop – family_archive dev`. **Create access key**.
4. Copy the **Access key** and **Secret access key** (or **Download .csv
   file**). The secret is shown only now. Store it in your password manager.
5. **Done**.

## 4. Add the local profile

```sh
aws configure --profile family-archive-dev
# AWS Access Key ID:     <access key>
# AWS Secret Access Key: <secret>
# Default region name:   us-east-2
# Default output format: json
```

This writes `~/.aws/credentials` and `~/.aws/config`; your existing
profiles are untouched. Delete the downloaded `.csv` once it's in the
password manager.

## 5. Verify

```sh
# Who am I? → ARN ends in user/family-archive-dev
aws sts get-caller-identity --profile family-archive-dev

# Can read → lists some keys
aws s3 ls s3://marias-family-archive/production/ --profile family-archive-dev | head

# Can't write → "An error occurred (AccessDenied) when calling the PutObject operation"
echo check | aws s3 cp - s3://marias-family-archive/dev-write-check.txt --profile family-archive-dev
```

If the last command **succeeds**, stop: the policy is wrong or a bucket
policy/ACL grants writes. Delete `dev-write-check.txt` (as root, in the S3
console), recheck step 1, and run the checks again.

## If the laptop is lost

IAM → Users → `family-archive-dev` → Security credentials → the key →
**Actions → Deactivate** (then **Delete**). The key could only ever read.

## Later (not part of this)

- Turn on MFA for the root account (IAM → Security recommendations).
  Ten minutes, independent of everything else here.
- Terraform: the bucket, this policy and user, and the production
  `family-archive-s3` user can be adopted with `terraform import` — nothing
  made by hand now has to be recreated.
- AWS Organizations / IAM Identity Center: worth it once there's more than
  one account (e.g. separate dev and prod accounts).
