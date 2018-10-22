# tf-api module

Module for the creating API Gateway by custom swagger API template

Check the [interpolation](https://www.terraform.io/docs/configuration/interpolation.html) rules

Here is an important note for the Swagger extension like `$ref`, it should be `$$ref`
Because:
```
You can escape interpolation with double dollar signs: $${foo} will be rendered as a literal ${foo}.
```

With TF resource
```
data "template_file" "swagger" {
  template = "${file("files/swagger.yaml")}"

  vars {
    name     = "${var.name}"
    env      = "${var.env}"
    dns_name = "${var.domain}"
  }
}
```

Example of Swagger file:
```yaml

```