---
date: 2016-09-13T09:00:00+00:00
title: API - Breeds
menu:
  main:
    parent: "API"
    identifier: "api-reference-breeds"
    weight: 35
draft: true
---
Breeds are static artifacts that describe individual services and can be referenced from blueprints or workflows. Read about [using breeds](documentation/using-vamp/breeds/).

## Actions
 
 * [List](/documentation/api/v9.9.9/api-breeds/#list-breeds) - return a list of all stored breeds
 * [Get](/documentation/api/v9.9.9/api-breeds/#get-single-breed) - get a single stored breed
 * [Create](/documentation/api/v9.9.9/api-breeds/#create-breed) - create a new breed 
 * [Update](/documentation/api/v9.9.9/api-breeds/#update-breed) - update a stored breed
 * [Delete](/documentation/api/v9.9.9/api-breeds/#delete-breed) - delete a stored breed

## Breed resource
You can define breeds inline or store them separately under a unique name and reference them from a blueprint, deployment or workflow resource.
The resource examples shown below are in YAML format. Vamp API requests and responses can be in JSON (default) or YAML format, see [common parameters](/documentation/api/v9.9.9/api-common-parameters) for details on how to set this. 

### Minimum resource
The minimum fields required to successfully store a breed.

```
name: sava:1.0.0
deployable: magneticio/sava:1.0.0

```

### API return resource
The fields returned by the API for stored breeds.

```
name: sava:1.0.0
kind: breed
deployable:
  type: container/docker
  definition: magneticio/sava:1.0.0
ports: {}
environment_variables: {}
constants: {}
arguments: []
dependencies: {}
```

 Field name        | Required | description          
 -----------------|--------|---------
name  |  yes  | a unique name to reference the breed
kind  |  optional  | The resource type. Required to [send multiple resources](/documentation/api/v9.9.9/api-overview/#send-multiple-resources-post-put-and-delete) to `/api/v1`
deployable  |  yes  |  the default deployable type is `container/docker`
ports  |  optional  |  
environtment_variables  |  optional  |
constants  |  optional  |
arguments  |  optional  |
dependencies  |  optional  |  

--------------  
  
## List breeds

Returns a list of all stored breeds. For details on pagination see [common parameters](/documentation/api/v9.9.9/api-common-parameters).

### Request
* `GET`
* /api/v1/breeds
* The request body should be empty.

### Response
If successful, will return a list of [breed resources](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `accept` format (default JSON). For details on pagination see [common parameters](/documentation/api/v9.9.9/api-common-parameters).

### Errors
* ???

--------------

## Get single breed

Returns a specific stored breed.

### Request
* `GET`
* `/api/v1/breeds/{breed_name}`
* The request body should be empty.

### Response
If successful, will return the specified [breed resource](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `accept` format (default JSON)

### Errors
* The requested resource could not be found.

--------------

## Create breed

Creates a breed with the specified fields.

### Request
* `POST` 
* `/api/v1/breeds`
* The request body should include at least the [minimum breed resource](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `content-type` format (default JSON). 

### Response
If successful, will return the created [breed resource](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `accept` format (default JSON).

### Errors
* ???

--------------

## Update breed

Updates the specified field(s) of a stored breed.

### Request
* `PUT`
* `/api/v1/breeds/{breed_name}`
* The request body should include at least the [minimum breed resource](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `content-type` format (default JSON). The `name` field must match the `breed_name` specified in the request syntax.

### Response
If successful, will return the updated [breed resource](/documentation/api/v9.9.9/api-breeds/#breed-resource) in the specified `accept` format (default JSON).

### Errors
* ???

--------------

## Delete breed

Deletes the specified breed. Note that delete operations are idempotent: sending a second request with the same content will not result in an error response (4xx).

### Request

* `DELETE`
* `/api/v1/breeds/{breed_name}`
* The request body should be empty.

### Response
A successful delete operation has status code 204 `No Content` or 202 `Accepted` with an empty response body.

### Errors
* ???

--------------