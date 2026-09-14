---
title: Dendritic, but better
description: Design a custom aspect-oriented layout and an DSL based on dendritic in Nix to declare and compose NixOS and Home Manager configurations, with automatic module discovery and host assembly.
date: 2026-09-15
tags:
  - philosophy
  - nixos
  - nix
  - system
status: published
---

## An Aspect-Oriented Layout for My Nix Configuration

I have been using the dendritic pattern for my Nix configuration for quite a while, I like the basic idea, a configuration should grow from small modules instead of being assembled from a few enormous host files. `flake-parts` gives those modules a reasonable structure, and tools such as `import-tree` remove most of the boring import plumbing.

But after using it for an actual multi-machine configuration, I started to dislike one part of the pattern.

Not the idea of dendritic configuration itself.

The interface around it.

So I ended up building a small DSL on top of the same ideas. The result is still based on `flake-parts`, still uses dendritic modules, still uses `import-tree`, and still produces normal NixOS configurations.

But the way modules are named, grouped, selected, and composed is different.

The source is available in my [flake repository](https://forge.asnk.io/sugar/flake).

## The Idea

The default combination of `flake-parts` and a dendritic layout is extremely flexible, sometimes a little too flexible.

A typical module eventually contains something like this:

```nix
{
  flake.modules.nixos.yorha = {
    # ...
  };

  flake.modules.homeManager.yorha = {
    # ...
  };
}
```

The file may already be called `yorha.nix`. The directory already tells me what kind of thing it is. Yet I still have to declare `yoraha` again.

The filesystem contains information, but the module interface mostly ignores it, this becomes even more noticeable once every feature in the system becomes its own file.

I don't really want this:

```text
2b.nix
  -> flake.modules.nixos.2b
```

What I want:

```text
2b.nix
  -> 2b
```

The filename should already be the name of the aspect.

There is another problem, the usual dendritic layout is commonly expressed around something close to:

```text
<class>.<aspect>
```

That is a good representation when every file is primarily an independently reusable module. But it is less convenient when I want the filesystem itself to become the module registry.

If the filename is automatically interpreted as the aspect name, then the class has to live somewhere else.

For my configuration:

```text
<aspect>.<class>
```

or, more concretely:

```text
<aspect>.nixos
<aspect>.home
```

It changes which part of the configuration owns composition. Besides I also wanted aspects to be composable at a higher level.

I have modules that are useful individually, but I normally do not select them individually. Even if I want to I can select them by importing `drivers.nixos` or `drivers.home`.

A machine is a desktop; A machine is a server; A machine has a development role.

In particular, I cannot simply treat one aspect as a function, import it from another aspect, pass some parameters into it, and continue pretending that everything is just an unrelated collection of modules.

There is tension between two goals:

```text
everything is independently reusable
```

and:

```text
everything is part of one coherent system
```

I eventually decided that my repository is a **system configuration first**.

I do not actually need every module in my personal system configuration to be a beautiful public API that another flake can consume independently, if I build something that should genuinely be reusable by other people, I can package it as its own project. So, my system repository does not need to pretend that every internal module is a library.

## My Approach

The basic change is simple:

```text
class.aspect
```

becomes:

```text
aspect.class
```

Instead of explicitly naming every exported module, I use `import-tree` to discover the files and an adapter to derive their identities from their paths.

For example:

```text
modules/apps/firefox.nix
```

becomes the `firefox` aspect.

Inside the file, I only need to describe which classes that aspect implements:

```nix
{
  nixos = {
    # NixOS module
  };

  home = {
    # Home Manager module
  };
}
```

The filename already answers:

> What is this?

And the directory answers:

> What is does?

So the file only needs to answer:

> Where does it apply?

`nixos` means a NixOS module, `home` means a Home Manager module. An aspect may provide either one or both. There is no reason for me to write `firefox` inside `firefox.nix` again.

Internally, regular aspect files are converted back into normal `flake.modules.nixos` and `flake.modules.homeManager` modules. So this is not a replacement for the module system.

**Roles and machines**

Not every file is interpreted in exactly the same way, the directory now has semantic meaning.

Roughly, I divide the tree into three kinds of things:

```text
modules/
├── apps/
├── services/
├── hardware/
├── ...
├── roles/
└── machines/
```

Normal directories such as `apps` and `services` define aspects, `roles` compose aspects, `machines` materialize complete systems.

The adapter determines that from the relative path of each file.

So a file under:

```text
roles/
```

is not just another application module, It is part of the composition layer.

And a file under:

```text
machines/
```

describes a system that should eventually become a `nixosConfiguration`.

This gives the repository a fairly simple direction:

```text
modules → roles → machines → nixosConfigurations
```

I find this much easier to reason about than treating every file as an equally generic module and reconstructing the architecture through manually written imports.

**Aspects are still selectable**

Internally, the adapter reconstructs all discovered modules into an aspect interface.

An aspect can contain:

```nix
{
  nixosModule = ...;
  homeModule = ...;
}
```

and selectors are generated for it:

```nix
aspect.nixos
aspect.home
```

This means a role can select the system side, the Home Manager side, or the complete aspect depending on what it needs.

**Helpers and parameterized aspects**

There was still one missing piece, some configuration cannot be expressed nicely as a completely closed module.

A good example is anything involving secrets.

I may have a generic service module, but the actual SOPS secret declarations are machine-specific, I do not want the generic module to know which secret path a specific machine uses. Same, I do not want to duplicate the service configuration inside every role or machine. So aspects may export helpers.

Instead of putting every possible value directly into the module, I can expose a function from that aspect and use something conceptually like:

```nix
withSomething {
  # machine- or role-specific values
}
```

The helper can then generate the configuration that belongs to that aspect.

The service knows that it needs a secret and the machine knows which secret it has.

The helpers themselves intentionally don't participate in normal module merging, they are attached to the selectable aspect as an interface for the composition layer.

So an aspect is not only:

```text
some NixOS options
```

It can also expose the small amount of vocabulary required to configure itself.

That starts to look less like a directory full of Nix modules and more like a tiny DSL for describing my systems.

**Turning it back into Nix**

Eventually all of this has to become something NixOS understands.

At the boundary, the adapter takes the selected aspects and reconstructs ordinary modules.

Machines provides information then the builder creates a normal:

```nix
nixpkgs.lib.nixosSystem
```

Home Manager is attached when required, same for Disko. And the hostname comes from the machine name.

The resulting systems are exported through:

```nix
flake.nixosConfigurations
```

So the final product is still boring Nix. The unusual part only exists while I am describing the system. I think that is an important property of this design.

I do not want a DSL that replaces NixOS.

I want a DSL that removes the repetitive parts between my filesystem and NixOS.

## What This Gives Me

The most obvious improvement is that files now have identities.

If I create:

```text
services/postgresql.nix
```

then its name is already `postgresql`.

I do not need to declare the same fact again inside the file, the repository also becomes easier to navigate, the path tells me what role a file plays in the architecture, the filename tells me which aspect it defines, the contents tell me how that aspect behaves, those three things no longer repeat each other.

There is also less explicit import management, `import-tree` discovers the module files automatically, the adapter classifies them, the aspect layer reconstructs them, roles and machines perform the actual selection, adding an ordinary feature generally means adding a file.

More importantly, my `flake.nix` can remain almost entirely infrastructure, the configuration is still based on `flake-parts`, module discovery is still automatic, inputs are still managed automatically.

If I want to evaluate a specific machine:

```sh
nh os switch <target>
```

I can.

If I am rebuilding the current machine:

```sh
nh os switch .
```

the normal hostname-based workflow still works.

An abstraction used for organizing configuration should not become an abstraction I have to fight every time I run the configuration.

## The Trade-offs

This design is absolutely not more flexible in every direction, it deliberately removes some flexibility.

The first loss is module independence.

In a conventional dendritic flake, individual modules naturally map to public flake module outputs, that makes it straightforward for another flake to consume one specific module from the repository, but my design does not optimize for that.

The aspect system is intended to be assembled into my system, individual pieces are implementation details of that system.

Technically, I could build more machinery to export everything again, I just do not think that machinery would buy me very much.

How often does somebody actually want:

```text
one random module from somebody else's complete personal system configuration
```

instead of the software that module configures?

If something becomes generally useful, I would rather make it a proper standalone project with its own repository, interface, documentation, and release lifecycle.

That seems cleaner than forcing my system configuration to behave like a public module collection forever.

The second trade-off is that the flake becomes more opinionated.

`flake-parts` itself gives me a lot of freedom, my adapter intentionally takes some of that freedom away, this repository wants to describe systems, wants files to become aspects, roles to compose those aspects, machines to instantiate those roles.

If I suddenly decide that the same repository should also become a large packaging monorepo, the abstraction starts getting in the way.

I can still escape into ordinary `flake-parts` when necessary, but doing too much of that defeats the point.

The final trade-off is probably the most controversial one.

The filesystem now has semantics.

This:

```text
roles/sugar.nix
```

does not mean the same thing as:

```text
services/sugar.nix
```

And this:

```text
machines/sugar.nix
```

You have to follow the layout, the `roles` and `machines` are special, and other directories generally contain aspects, the structure is no longer merely decorative.

Normally, making directory names part of program semantics is something I would be cautious about.

In this case, it is intentional. This is a system configuration repository, the directory hierarchy already communicates architecture to the person reading it.

So yes, this DSL has rules, but it eventually all of it disappears into an ordinary NixOS configuration.

That is enough.
