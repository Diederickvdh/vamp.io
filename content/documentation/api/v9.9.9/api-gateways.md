---
date: 2016-09-13T09:00:00+00:00
title: API - Gateways
menu:
  main:
    parent: "API"
    identifier: "api-reference-gateways"
    weight: 37
draft: true
---
intro text. Read about [using gateways](documentation/using-vamp/gateways/).

## Methods
 
 * [List](/documentation/api/v9.9.9/api-gateways/#list-gateways) - return a list of all gateways
 * [Get](/documentation/api/v9.9.9/api-gateways/#get-a-single-gateway) - get a single gateway
 * [Create](/documentation/api/v9.9.9/api-gateways/#create-a-gateway) - create a new gateway 
 * [Update](/documentation/api/v9.9.9/api-gateways/#update-a-gateway) - update a gateway
 * [Delete](/documentation/api/v9.9.9/api-gateways/#delete-a-gateway) - delete a gateway

## Gateway resource
You can define gateways inline or store them separately under a unique name and reference them from a blueprint, breed or deployment resource.
The resource examples shown below are in YAML format. Vamp API requests and responses can be in JSON (default) or YAML format, see [common parameters](/documentation/api/v9.9.9/api-common-parameters) for details on how to set this. 

### Minimum resource

```

```

### API return resource

```

```

 Field name        | description          
 -----------------|-----------------
  |  
  |
  
## List gateways

Returns a list of all gateways. For details on pagination see [common parameters](/documentation/api/v9.9.9/api-common-parameters)

### Request syntax
    GET /api/v1/gateways

| Request parameters         | options           | default          | description       |
| ----------------- |:-----------------:|:----------------:| -----------------:|
|  |  |  |  |

### Request body
The request body should be empty.

### Response syntax


### Errors
* ???

## Examples

See [gateways - A/B TEST TWO DEPLOYMENTS USING ROUTE WEIGHT](/documentation/using-vamp/gateways/#example-a-b-test-two-deployments-using-route-weight)