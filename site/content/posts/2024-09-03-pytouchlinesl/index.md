---
title: "Writing a Home Assistant Core Integration: Part 1"
summary: |
  Part 1 of a micro-series of blog posts that outlines my
  journey toward authoring a Home Assistant Core integration
  for the Roth Touchline SL heating system.

  This first post covers the design and build of a Python
  API client for Roth's upstream API that controls the
  underfloor heating systems.
tags:
  - Development
  - Python
  - NixOS
  - Nix
  - uv
  - Home Assistant
  - API
  - Blog
layout: post
cover: cover.png
coverAlt: |
  A screenshot of the header on pypi.org, showing the landing page
  for the pytouchlinesl python library, at version 0.1.5.
---

## Introduction

Back in March, my family and I moved into a new home. It's quite a modern affair - pre-installed with solar panels (and associated inverter/battery storage), and uses an air source heat pump to heat the house with underfloor heating. Being a new renovation, nearly all of the appliances and components in the house have a form of internet connectivity - some more useful than others.

Since day 1, I've been hoping to consolidate all of the various applications, data feeds and functions into one single place - and critically one single app on my iPhone! I've been a long-time listener to the [Self Hosted](https://selfhosted.show/) podcast, which often extol the virtues of [Home Assistant](https://www.home-assistant.io/). I've got no prior experience with Home Assistant, but for the last three months I've been running it on my home server, which a collection of custom integrations and hacks to bring in my underfloor heating and solar inverter.

The underfloor heating controller is a [Roth Touchline SL](https://www.roth-uk.com/products/control-systems/roth-touchliner-sl-wireless-system) system. In my set up, there is a single "module" which represents my house, and a number of "zones" which represent different rooms.

There was unfortunately no integration for this system in Home Assistant - [there is one](https://www.home-assistant.io/integrations/touchline/) for the previous generation "Roth Touchline", but this appears to function over the LAN, whereas the Touchline SL system is controlled over the internet using their API.

After reading the source code of a few other climate integrations in Home Assistant, it became clear to me that the first step was to create a Python client for the API which could be used in the integration. This post will cover the design, implementation and limitations of the library I wrote: [pytouchlinesl](https://pypi.org/project/pytouchlinesl/).

## Designing the library

### Upstream API

The normal way one would interact with a Roth Touchline SL system is through one of their mobile apps, or through their [online portal](https://roth-touchlinesl.com/). The mobile app seems to be quite a lightweight wrapper around the web application, and I've not been able to detect any difference in functionality.

A bit of searching uncovered that Roth also provide an API for the Touchline SL system, and an [OpenAPI spec](https://api-documentation.roth-touchlinesl.com/). This made the process significantly easier, though there are some discrepancies in what is documented compared with how the API _actually_ behaves. It feels to me like the API may have evolved, and the documentation has remained static - or perhaps it was always inaccurate? Either way, I did have to spent quite a bit of time essentially [fuzzing](https://en.wikipedia.org/wiki/Fuzzing) the API to work out the correct set of parameters to send to some endpoints.

I also studied the web application a little using the Chrome Dev Tools. Of all the endpoints documented, it seemed like I'd likely only need the following:

- `POST /authentication`: authenticates with the API, taking a username and password, and returning a token
- `GET /users/{user_id}/modules`: returns a list of modules associated with the user
- `GET /users/{user_id}/modules/{module_udid}`: returns details of a specific module (zones, schedules, etc.)

There is a slight awkwardness here, in that the last endpoint returns _all_ of the data - for all zones, all schedules, etc. This feels a little inefficient, but I couldn't find a way of getting information about a specific zone, or a specific schedule. The web application seems to rely upon polling the (undocumented) endpoint `GET /users/{user_id}/modules/{module_id}/update/data/parents/[]/alarm_ids/[]/last_update/{timestamp}`, which essentially delivers deltas in the data since a given timestamp. This is useful in the context of the app because it can request the full dataset once, then request only changes from there, keeping the app state up to date without requesting the whole dataset.

Making changes to the configuration of zones and their temperatures is also a little fragmented. In essence, one can:

- Set a zone to a constant temperature: `POST /users/{user_id}/modules/{module_udid}/zones`
- Place a zone on a global schedule: `POST /users/{user_id}/modules/{module_udid}/zones/{zone_id}/global_schedule`
- Place a zone on a local schedule: `POST /users/{user_id}/modules/{module_udid}/zones/{zone_id}/local_schedule`

The first is relatively self-explanatory - this enables a zone to be set to a constant temperature, for example 19.0C. Touchline SL modules also support a number of "Global Schedules" - these schedules contain time periods for the specified zones to reach certain temps - in the case of a global schedule, multiple zones can be involved, while a local schedule is specific to a single zone. The awkwardness in the API here, is that to "add" a zone to a global schedule, you must re-specify all the details of the global schedule, and specify all of the zones that should be on the schedule...

### Basic Requirements

If you look through the [API documentation](https://api-documentation.roth-touchlinesl.com/), there are many endpoints that could be supported. In order to fulfil the basic functionality of my Home Assistant integration, I limited the requirements of the first version to:

- Authenticate with the API using a username and password
- List modules associated with the account
- Get a specific module from the account
- Get a specific zone from a specific module including details like current/target temp
- Get a list of global schedules
- Get a specific global schedule
- Assign a constant temperature to a zone
- Assign a zone to a specific global schedule

### Outline design/experience

With those requirements in mind, I came up with a rough sketch of how I'd like the library to behave:

```python
tsl = TouchlineSL(username="foo", password="bar")
module = await tsl.module(id="deadbeef")

lounge = module.zone_by_name("Lounge")
kitchen = module.zone(1234)

print(f"Lounge temp: {lounge.current_temperature}, Lounge humidity: {lounge.humidity}")
print(f"Kitchen temp: {kitchen.current_temperature}, Kitchen humidity: {kitchen.humidity}")

await kitchen.set_temperature(temperature=20.0)

living_spaces = await tsl.schedule_by_name(schedule_name="Living Spaces")
await lounge.set_schedule(living_spaces.id)
```

And from that came a reasonable outline of the structure of the library:

```python
class TouchlineSL:
  # Construct a class that represents a Touchline SL account
  def __init__( self, *, username: str | None = None, password: str | None = None)
  # Get a list of modules associated with the account
  async def modules(self) -> list[Module]
  # Get a specific module, by ID
  async def module(self, *, module_id: str) -> Module | None

class Module:
  # Get a list of zones from the module, optionally including disabled zones
  async def zones(self, *, include_off: bool = False) -> list[Zone]
  # Get a specific zone, by ID
  async def zone(self, zone_id: int) -> Zone | None
  # Get a specific zone, by name
  async def zone_by_name(self, zone_name: str) -> Zone | None
  # Get a list of global schedules
  async def schedules(self) -> list[Schedule]:
  # Get a specific schedule, by ID
  async def schedule(self, schedule_id: int) -> Schedule | None
  # Get a specific schedule, by name
  async def schedule_by_name(self, schedule_name: int) -> Schedule | None

class Zone:
  # Get the schedule the zone is assigned to
  def schedule(self) -> Schedule | None
  # Set the zone to a constant temperature
  async def set_temperature(self, temperature: float)
  # Assign the zone to a specific schedule
  async def set_schedule(self, schedule_id: int)
```

Note that after reading the code from other `climate` integrations in Home Assistant, it became clear to me that they favour the use of `async` libraries, and thus my library was designed to use `asyncio` from the start.

## Python tools/libraries

I've been writing Python for quite a long time now - not that I'd claim to be particularly expert at it, nor much of a fan.

There are a couple of things I've found tiresome over the years, but things do seem to be looking up. I've always found the package management/distribution to be awkward, and I can't be the only one if the number of projects looking to target that problem is anything to go by (e.g. [`poetry`](https://python-poetry.org/), [`rye`](https://rye.astral.sh/), [`uv`](https://github.com/astral-sh/uv), [`pdm`](https://pdm-project.org/en/latest/), etc.). Part of this seems to come from fractures in the community itself - there (still!) appears to be disagreements surrounding PEPs such as [PEP-621](https://peps.python.org/pep-0621/) which introduced `pyproject.toml` as a way of managing project metadata and dependencies, with the maintainers of some high-profile and widely adopted libraries essentially refusing to adopt it.

That said, there are a couple of things I've been meaning to try in anger, and this project was a good opportunity to do so:

### [`uv`](https://github.com/astral-sh/uv)

Developed by [Astral](https://astral.sh), the people behind [`ruff`](https://github.com/astral-sh/ruff), `uv` is the "new shiny" at the time of writing, and I can understand why. Pitched as "Cargo, but for Python", it aims to solve a myriad of problems in the Python ecosystem. `uv` can handle the download/install of multiple Python versions, the creation of virtual environments, running Python tools in a one-off fashion (like `pipx`), locking dependencies deeply in a project (by hash) and still maintains a `pip` compatible command-line experience with `uv pip ...`. To add to all of that, it's _ridiculously_ fast - on a couple of occasions I've actually found myself wondering if it _did anything_ when installing dependencies for large projects, because it's so much faster than I'm used to.

### [`pydantic`](https://docs.pydantic.dev/latest/)

Pydantic is a data validation library for Python. It's entirely driven by Python's type-hints which means that you get nice integration with language servers. Pydantic allows you define data models in native Python, but emit standard JSON Schema docs for models. It's integrated quite widely across the Python ecosystem, and to me feels like it bridges the gap between what I hoped type annotations would do for Python, and what they actually do in reality!

## Implementation

With a basic design in mind, and tooling ready to go, I set about building the library itself. It was now time to reconcile my intended design with the realities of the provisions made by the upstream API. I mentioned previously that the only useful endpoint for getting information about zones/schedules would in fact return _all_ of the data for a given module - too many calls to this endpoint would result in poor performance, so I knew I'd need to introduce some sort of caching to make the experience better. In reality, the details of underfloor heating zones don't tend to change _that_ often.

### Client implementation

For the underlying API client implementation, I opted for the following:

- [`BaseClient`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/base.py): a class which inherits from Python's [`abc.ABC`](https://docs.python.org/3/library/abc.html#abc.ABC). This enables the creation of multiple client implementations by defining of the set of methods/properties that any client interacting with the Roth API should define. This decision is primarily to support testing through dependency injection, rather than mocking (more details on that later).
- [`RothAPI`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/client.py): a concrete implementation of the `BaseClient` abstract class. It is here that I built the actual implementation of the client which handles authentication, `GET`ing and `POST`ing data, caching, and marshalling API responses into the correct types (defined with Pydantic).

Also included in the [`client` package](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client) is the [`models` package](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/models). The `models` package contains (mostly) auto-generated Pydantic models based on real-life responses I got from the API. This is really a function of laziness, but was a convenient way to get type annotated models for the responses I was receiving from the API. Each time I hit a new endpoint, I took the JSON result and did a quick conversion with https://jsontopydantic.com/, before manually adjusting names and updating some fields with `Literals`.

### Caching

I mentioned earlier that I intended to implement some basic caching - and I want to emphasise the word basic here! I am aware of various plugins for `aiohttp` (and other request libraries) that would perhaps implement all kinds of fancy caching, but in reality my requirements here were quite simple, so I chose to keep the number of dependencies down, and implement it in the library. In this case, caching is implemented on the [`Module`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py) class - this is because the large blob of data that needs to be requested in order to get details about a module and its zones/schedules is requested per module.

The caching works like this:

The [`Module`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py) class has "private" attributes named [`_raw_data`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L62) and [`_last_fetched`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L64):

```python
class Module:
    def __init__(
        self,
        *,
        client: BaseClient,
        module_data: AccountModuleModel,
        cache_validity: int = 30,
    ):
        # ...

        # Raw data about the zones, schedules, tiles in the module
        self._raw_data: ModuleModel
        # Unix timestamp representing the last time the _raw_data was fetched
        self._last_fetched = 0
        self._cache_validity = cache_validity

        # ...
```

There is only one method on this class that calls to the underlying client, and that's another "private" method named [`_data`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L70). This method takes an option `refresh` keyword argument, which forces the `_raw_data` attribute to be updated, but by default will only fetch data if the cached data has expired (after the number of seconds specified in `self._cache_validity`). If `refresh` is false, and the cache hasn't expired, it simply returns the stored raw data:

```python
async def _data(self, *, refresh: bool = False) -> ModuleModel:
    """Get the raw representation of the module from the upstream API.

    If the data has never been fetched from upstream, or the data is older
    than the cache validity period, then the data is refreshed using the
    upstream API.

    Args:
        refresh: (Optional): Force the data to be refreshed using the API.
    """
    if refresh or (round(time.time() * 1000) - self._last_fetched) > self._cache_validity:
        self._raw_data = await self._client.module(self.id)
        self._last_fetched = round(time.time() * 1000)

    return self._raw_data
```

Each of the public methods (`zones()`, `zone()`, `schedule()`, etc.) can now access the raw data through the `_data()` method, and pass through the refresh flag which is exposed. This means that any developer consuming this library can chose to live with the caching, or override it and force a refresh like so:

```python
tsl = TouchlineSL(username="foo", password="bar")
module = await tsl.module(id="deadbeef")

# Request a zone, accepting cached data (default)
zone = await module.zone_by_name("kitchen")
# Or force the data to be refreshed using the upstream API
zone = await module.zone_by_name("kitchen", refresh=True)
```

## Testing

## Publishing

## Contributing to `nixpkgs`

## Summary
