---
title: One-Job actions runner on Serverless Cluster
description: An exploration of building a one-job Forgejo Actions Runner architecture using serverless Kubernetes and ephemeral OCI environments.
date: 2026-09-16
tags:
  - infrastructure
  - aliyun
status: published
---

## The idea

A CI Runner is usually treated as a long-running service.

The traditional self-hosted Runner model looks like:

```text
Machine
 └── Runner daemon
      ├── Job 1
      ├── Job 2
      └── Job 3
```

The Runner machine exists first, waits for jobs, and executes workloads when they arrive.

However, a CI job itself is not a long-running service. It is a temporary workload:

```
Job arrives > Create execution environment > Execute task > Destroy environment
```

A Runner should not be a server daemon waiting for work, it should be a temporary execution environment created for a specific job, the lifetime of a Runner should match the lifetime of the job.

---

## The problem with traditional self-hosted Runners

Traditional self-hosted Runners work well for small workloads, but they become inefficient when CI workloads become larger and more dynamic.

### Expensive idle resources

A permanent Runner machine needs to be sized according to peak workload requirements rather than average usage.

For compute-intensive workloads such as Linux Kernel compilation or large software builds, the required instance size can become expensive while remaining mostly idle when no CI jobs are running.

This creates a reserved-capacity model is: Allocated resources for CPU / Memory / Storage then Paid even when idle.

### Limited concurrency

A static Runner machine has a fixed amount of resources.

When multiple CI jobs arrive simultaneously:

```
Job Queue
├── Job A
├── Job B
└── Job C
```

the system cannot automatically create additional execution capacity.

Running multiple Runner processes on the same machine increases concurrency, but all jobs compete for:

- CPU
- Memory
- Disk I/O
- Network bandwidth

This can introduce unpredictable performance degradation between unrelated workloads.

### Lack of workload-based resource flexibility

Different CI workloads require different resource profiles.

For example:

- A documentation build may only require a small amount of CPU and memory.
- A Linux Kernel build may require multiple CPU cores and a larger build environment.

A fixed Runner machine cannot efficiently adapt to these differences, by changing the instance size requires manual operations and cannot provide immediate elasticity.

### Environment drift

Long-running Runner machines accumulate state over time:

- toolchains
- dependencies
- caches
- temporary files
- configurations

After long periods of usage, the environment may no longer be predictable.

This can cause:

- dependency conflicts
- inconsistent build results
- difficult debugging

OCI images provide a cleaner execution model: `forgejo-runner + toolchain + dependencies + configuration` results a reproducible Runner environment.

Each CI job starts from a known state and runs in an isolated environment.

---

## Motivation

The goal is to replace the traditional static Runner model with an elastic one-job Runner architecture.

Instead of maintaining permanent Runner servers:

- Create Runner environments only when jobs exist.
- Allocate resources according to workload requirements.
- Execute exactly one CI job per Runner.
- Destroy the environment immediately after completion.
- Keep execution environments reproducible through immutable OCI images.

---

## Architecture

The system is built on:

- Forgejo as the Git Forge and CI platform.
- Aliyun ACS as the serverless Kubernetes execution platform.
- KEDA for workload-based scaling.
- OCI images as reproducible Runner environments.

---

## Serverless execution environment

Aliyun ACS provides a serverless Kubernetes environment where basic cluster components are available without additional charges.

Instead of maintaining dedicated Kubernetes worker nodes, workloads run on Flexible Container resources and are billed based on actual CPU and memory usage while pods are running.

This matches the lifecycle model of CI workloads:

- No CI job > No compute resource
- CI job arrives > Create Runner container
- Job completes > Release resources

The infrastructure cost follows actual workload demand instead of requiring permanently allocated Runner capacity.

---

## One-job Runner implementation

The system monitors pending CI jobs by querying the Forgejo API.

When a job requires execution, the Runner controller creates an ephemeral Runner workload.

Each Runner is packaged together with `forgejo-runner` inside a predefined OCI image.

An OCI Image = forgejo-runner + tool environment + build dependencies + runtime configuration

---

## Workload-based Runner selection

Different CI workloads can use different Runner environments, runner labels are used to identify the required execution environment.

For example:

```
acs-nix
acs-linux
acs-build
```

A Nix-based build can request:

```
runs-on: acs-nix
```

KEDA monitors these workloads and triggers the creation of corresponding Runner containers when matching jobs appear.

This allows different workloads to use different OCI images and resource configurations.

---

## Runner lifecycle

Each Runner is designed to execute exactly one CI job.

1. Forgejo creates a pending job
2. Runner controller detects the workload
3. KEDA triggers Kubernetes scaling
4. ACS creates an OCI Runner container
5. Runner registers itself to Forgejo
6. Runner executes one job
7. Runner unregisters itself
8. Container exits
9. Kubernetes removes the workload

---

## Why one-job Runner?

Traditional Runner:

```
Lifetime: Months, with high costs
```

One-job Runner:

```
Lifetime: Minutes, only runs a Single CI job with flexable costs
```

The one-job model provides:

- no long-term state accumulation
- no dependency drift
- improved isolation
- automatic scaling
- lower idle resource cost

---

## Result

The final architecture changes the CI resource model from:

- Always running servers
- Pay for capacity
- Regardless of usage

to:

- Ephemeral execution environments
- Pay only when workloads execute

A Runner is no longer treated as a permanent machine.

It becomes a temporary, reproducible execution environment created for exactly one purpose.

---

## Trade-offs

Although the one-job Runner architecture improves resource utilization and scalability, it also introduces several trade-offs.

### Cross-region network overhead

Running ephemeral Runners across different regions provides more flexibility in resource allocation, but it can introduce additional network latency and bandwidth costs.

When the Runner is deployed in a different region from the Git Forge platform or other required resources, cross-region traffic may increase execution time and introduce additional network costs.

For workloads with large repositories or heavy artifact transfer, keeping the Runner close to the primary data source can significantly improve performance.

### Runner startup latency

Unlike traditional long-running Runners, ephemeral Runners must be created before executing a job.

The startup lifecycle includes:

1. Pending job
2. Create container workload
3. Pull OCI image
4. Initialize environment
5. Register Runner
6. Execute the job

---

## The tools

For this special need, I just create a tool called acs-k8s, a cli for creating and controlling the ACS Cluster.

Link here: [Asnk Forge](https://forge.asnk.io/sugar/acs-k8s)
