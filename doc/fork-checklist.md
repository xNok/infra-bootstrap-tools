# What should you do to use the repository after you forked it

## Terraform

The repository assumes that you are using [Terraform Cloud](https://www.hashicorp.com/products/terraform) a a remote Backend. Note that Terraform Cloud is free up to `500 resources` a limit that this repo doesn't reach.

First you need to chnage all the `backend.tf` to use the state backend of your choice, you can keep using Terrafrom Cloud simply change the organisation name with yours.


