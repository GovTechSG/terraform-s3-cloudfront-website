# s3-cloudfront-website
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| aws.us-east-1 | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudfront\_origin\_path | Origin path of CloudFront | `string` | `""` | no |
| cors\_allowed\_origins | CORS allowed origins | `list(string)` | `[]` | no |
| domain\_names | domain names to serve site on | `list(string)` | n/a | yes |
| enable\_acm\_validation | Validates ACM by updating route 53 DNS | `bool` | `false` | no |
| lambda\_function\_associations | CloudFront Lambda function associations. key is CloudFront event type and value is lambda function ARN with version | `map(string)` | `{}` | no |
| redirect\_domain\_names | domain names to redirect to `domain_names` | `list(string)` | n/a | yes |
| route53\_zone\_id | Route53 Zone ID | `string` | `""` | no |
| s3\_logging\_bucket | Bucket which will store s3 access logs | `string` | `""` | no |
| s3\_logging\_bucket\_prefix | Bucket which will store s3 access logs | `string` | `""` | no |
| save\_access\_log | whether save cloudfront access log to S3 | `bool` | `false` | no |
| service\_name | tagged with service name | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cache\_invalidation\_command | CloudFront edge cache invalidation command. /path/to/invalidation/resource is like /index.html /error.html |
| cloudfront\_distribution\_main\_arn | ARN of cloudfront distribution |
| cloudfront\_distribution\_main\_domain\_name | Domain URL of cloudfront distribution |
| cloudfront\_distribution\_main\_etag | ETag of cloudfront distribution |
| cloudfront\_distribution\_main\_hosted\_zone\_id | hosted zone id of cloudfront distribution |
| cloudfront\_distribution\_redirect\_arn | ARN of cloudfront distribution |
| cloudfront\_distribution\_redirect\_domain\_name | Domain URL of cloudfront distribution |
| cloudfront\_distribution\_redirect\_etag | ETag of cloudfront distribution |
| cloudfront\_distribution\_redirect\_hosted\_zone\_id | hosted zone id of cloudfront distribution |
| cloudfront\_oai\_cloudfront\_access\_identity\_path | A shortcut to the full path for the origin access identity to use in CloudFront |
| cloudfront\_oai\_etag | n/a |
| cloudfront\_oai\_iam\_arn | A pre-generated ARN for use in S3 bucket policies |
| cloudfront\_oai\_s3\_canonical\_user\_id | n/a |
| s3\_main\_arn | ARN of s3 hosting index.html of site |
| s3\_main\_website\_domain | n/a |
| s3\_main\_website\_endpoint | n/a |
| s3\_redirec\_website\_endpoint | n/a |
| s3\_redirect\_arn | ARN of s3 hosting redirection to www. |
| s3\_redirect\_website\_domain | n/a |

