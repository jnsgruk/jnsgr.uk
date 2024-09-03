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

Back in March, my family and I moved into a new home. It's a modern construction which came with solar panels (and associated inverter/battery storage), and uses an [air source heat pump](https://en.wikipedia.org/wiki/Air_source_heat_pump) to heat the house with underfloor heating. Being a new renovation, nearly all of the appliances and components in the house have a form of internet connectivity (some more useful than others!).

Since day 1, I've been hoping to consolidate all of the various applications, data feeds and functions into one single place. I've been a long-time listener to the [Self Hosted](https://selfhosted.show/) podcast, which often extols the virtues of [Home Assistant](https://www.home-assistant.io/). I've got no prior experience with Home Assistant, but for the last three months I've been running it on my home server, with a collection of custom integrations and hacks that enable me to control the underfloor heating and solar inverter.

The underfloor heating controller is a [Roth Touchline SL](https://www.roth-uk.com/products/control-systems/roth-touchliner-sl-wireless-system) system. In my set up, there is a single "module" which represents my house, and a number of "zones" which represent different rooms.

There was unfortunately no integration for this system in Home Assistant - [there is one](https://www.home-assistant.io/integrations/touchline/) for the previous generation "Roth Touchline", but this appears to function over the LAN, whereas the Touchline SL system is controlled over the internet using their API.

After reading the source code of a few other climate integrations in Home Assistant, it became clear to me that the first step was to create a Python client for the API which could be used in the integration.

This post will cover the design, implementation and limitations of the library I wrote: [pytouchlinesl](https://pypi.org/project/pytouchlinesl/). If you came here to read about writing code _for Home Assistant_, you'll have to wait for the next post! 😉

## Designing the library

### Upstream API

Usually, one would interact with a Roth Touchline SL system through their mobile apps, or through their [online portal](https://roth-touchlinesl.com/). The mobile app seems to be quite a lightweight wrapper around the web application, and I've not been able to detect any difference in functionality.

A bit of searching uncovered that Roth also provide an API for the Touchline SL system, and an [OpenAPI spec](https://api-documentation.roth-touchlinesl.com/). This made the process significantly easier, though there are some discrepancies in what is documented compared with how the API _actually_ behaves. It feels to me like the API may have evolved, and the documentation has remained static - or perhaps it was always inaccurate? Either way, I spent quite a bit of time manually [fuzzing](https://en.wikipedia.org/wiki/Fuzzing) the API to work out the correct set of parameters for some endpoints.

I also studied the web application using the Chrome Dev Tools. Of all the endpoints documented, it seemed like I'd only need the following:

- `POST /authentication`: authenticates with the API, taking a username and password, and returning a token
- `GET /users/{user_id}/modules`: returns a list of modules associated with the user
- `GET /users/{user_id}/modules/{module_udid}`: returns details of a specific module (zones, schedules, etc.)

There is a slight awkwardness here, in that the last endpoint returns _all_ of the data - for all zones, all schedules, etc. This feels inefficient, but I couldn't find a way of getting information about a specific zone, or a specific schedule. The web application seems to rely upon polling the (undocumented) endpoint `GET /users/{user_id}/modules/{module_id}/update/data/parents/[]/alarm_ids/[]/last_update/{timestamp}`, which delivers deltas in the data since a given timestamp. This is useful in the context of the app because it can request the full dataset once, then request only changes from that point onwards, keeping the app state up to date without requesting the whole dataset.

Making changes to the configuration of zones and their temperatures is also fragmented. In essence, one can:

- Set a zone to a constant temperature: `POST /users/{user_id}/modules/{module_udid}/zones`
- Place a zone on a global schedule: `POST /users/{user_id}/modules/{module_udid}/zones/{zone_id}/global_schedule`
- Place a zone on a local schedule: `POST /users/{user_id}/modules/{module_udid}/zones/{zone_id}/local_schedule`

The first is self-explanatory, enabling a zone to be set to a constant temperature (`19.0C`, for example). Touchline SL modules also support "schedules" which contain time periods for the specified zones to reach certain temperatures. In the case of a "Global Schedule", multiple zones can be assigned, while a "Local Schedule" is specific to a single zone. The awkwardness in the API here is that to "add" a zone to a global schedule, you must re-specify the entire schedule, and specify all of the zones that should be on the schedule...

### Basic Requirements

In order to fulfil the basic functionality of my (future) Home Assistant integration, I limited the requirements of the first version to:

- Authenticate with the API using a username and password
- List modules associated with the account
- Get a specific module
- Get a specific zone
- Get a list of global schedules
- Get a specific global schedule
- Assign a constant temperature to a zone
- Assign a zone to a specific global schedule

I don't use local schedules in my system, so I've omitted them for now, though updating the library to support them would be trivial.

### Outline design/experience

With those requirements in mind, I came up with a rough sketch of how I'd like the library to behave:

```python
tsl = TouchlineSL(username="foo", password="bar")
module = await tsl.module(id="deadbeef")

lounge = module.zone_by_name("Lounge")
kitchen = module.zone(1234)

# Properties should be available such as:
#    lounge.current_temperature
#    kitchen.humidity

await kitchen.set_temperature(temperature=20.0)

living_spaces = await tsl.schedule_by_name(schedule_name="Living Spaces")
await lounge.set_schedule(living_spaces.id)
```

And from that came a reasonable outline of the API for the library:

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

There are a couple of things I've found tiresome about Python over the years, but things do seem to be looking up. I've always found the package management and distribution to be awkward, and I can't be the only one if the number of projects looking to target that problem is anything to go by (e.g. [`poetry`](https://python-poetry.org/), [`rye`](https://rye.astral.sh/), [`uv`](https://github.com/astral-sh/uv), [`pdm`](https://pdm-project.org/en/latest/), etc.).

Part of this seems to come from fractures in the community itself - there (still!) appears to be disagreements surrounding PEPs such as [PEP-621](https://peps.python.org/pep-0621/) which introduced `pyproject.toml` as a way of managing project metadata and dependencies, with the maintainers of some high-profile and widely adopted libraries refusing to adopt it.

That said, there are a couple of things I've been meaning to try in anger, and this project was a good opportunity to do so:

### [`uv`](https://github.com/astral-sh/uv)

Developed by [Astral](https://astral.sh), `uv` is the "new shiny" at the time of writing, and I can understand why. Pitched as "Cargo, but for Python", it aims to solve a myriad of problems in the Python ecosystem. `uv` can handle the download/install of multiple Python versions, the creation of virtual environments, running Python tools in a one-off fashion (like `pipx`), locking dependencies deeply in a project (by hash) and still maintains a `pip` compatible command-line experience with `uv pip`. To add to all of that, it's _ridiculously_ fast; on a couple of occasions I've actually found myself wondering if it _did anything_ when installing dependencies for large projects, because it's so much faster than I'm used to.

### [`pydantic`](https://docs.pydantic.dev/latest/)

Pydantic is a data validation library for Python. It's entirely driven by Python's type-hints which means that you get nice integration with language servers. Pydantic allows you define data models in native Python, but emit standard JSON Schema docs for models. It's integrated quite widely across the Python ecosystem, and to me feels like it bridges the gap between what I hoped type annotations would do for Python, and what they actually do in reality!

### [`ruff`](https://github.com/astral-sh/ruff)

I've been using this one for at least the last year for all my Python linting and formatting needs, but I still feel it deserves a call out. There have been a couple of small changes to command line API and such along the way, but overall I've found it to be a dramatic improvement over my last setup - which comprised of [`black`](https://github.com/psf/black), [`isort`](https://pycqa.github.io/isort/), [`flake8`](https://pypi.org/project/flake8/) and a pile of plugins. I had no particular beef with `black`, but I find `flake8`'s lack of `pyproject.toml` support irritating, and grew tired of plugins failing as `flake8` released new versions.

In my experience, `ruff` is stupid fast, and because it ships `flake8`-compatible rules for all of the plugins I was using as one bundle, they never break. It's also nice to just have _one tool_ to use everywhere. If you're interested, you can see how I configure `ruff` in the [`pyproject.toml`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pyproject.toml#L34).

## Implementation

With a basic design in mind, and tooling ready to go, I set about building the library itself. It was now time to reconcile my intended design with the realities of the provisions made by the upstream API.

I mentioned previously that the only useful endpoint for getting information about zones/schedules would in fact return _all_ of the data for a given module. Too many calls to this endpoint would likely result in poor performance, so I wanted to introduce some basic caching along the way.

### Client implementation

For the underlying API client implementation, I opted for the following:

- [`BaseClient`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/base.py): a class which inherits from Python's [`abc.ABC`](https://docs.python.org/3/library/abc.html#abc.ABC). This enables the creation of multiple client implementations by defining of the set of methods/properties that any client interacting with the Roth API should define. This decision is primarily to support testing through dependency injection, rather than mocking with patches (more details on that later).
- [`RothAPI`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/client.py): a concrete implementation of the `BaseClient` abstract class. It is here that I built the actual implementation of the client which handles authentication, `GET`ing and `POST`ing data, caching, and marshalling API responses into the correct types (defined with Pydantic).

Also included in the [`client`](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client) package is the [`models`](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/client/models) package. The `models` package contains (mostly) auto-generated Pydantic models based on real-life responses I got from the API. This is really a function of laziness, but was a convenient way to get type annotated models for the responses I was receiving from the API. Each time I hit a new endpoint, I took the JSON result and did a quick conversion with https://jsontopydantic.com/, before manually adjusting names and updating some fields with `Literals`.

### Caching

I mentioned earlier that I wanted to implement some basic caching. While I am aware of various plugins for `aiohttp` (and other request libraries) that could handle this for me, my requirements were quite simple, so I chose to just build it into the library. In this case, caching is implemented on the [`Module`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py) class. This is because the large blob of data that is requested to populate details about a module and its zones/schedules is requested _per module_.

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

There is only one method on this class that calls the underlying client, and that's another "private" method named [`_data`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L70). This method takes an optional `refresh` keyword argument, which forces the `_raw_data` attribute to be updated, but by default will only fetch data if the cached data has expired (after the number of seconds specified in `self._cache_validity`). If `refresh` is false, and the cache hasn't expired, it simply returns the stored raw data:

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

Each of the public methods ([`zones()`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L92), [`zone()`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L112), [`schedule()`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/module.py#L145), etc.) access the raw data through the `_data()` method, and pass through the refresh flag which is exposed. This means that any developer consuming this library can chose to live with the caching, or override it and force a refresh like so:

```python
tsl = TouchlineSL(username="foo", password="bar")
module = await tsl.module(id="deadbeef")

# Request a zone, accepting cached data (default)
zone = await module.zone_by_name("kitchen")
# Or force the data to be refreshed using the upstream API
zone = await module.zone_by_name("kitchen", refresh=True)
```

## Testing, CI & Publishing

### Testing

In the previous section, I described how I'd set up an abstract base class for the API client, then created an implementation of that for the actual Roth API. One of the main reasons I like this pattern for API clients is that it simplifies testing and reduces the need for monkey patching or traditional mocking (yes, I know the fake API client is sort of a mock...).

Because `TouchlineSL` can [optionally be constructed](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/pytouchlinesl/touchlinesl.py#L33) with any client that implements `BaseClient`'s abstract base class, it's trivial to implement a fake API backend that returns fixture data to be used in testing. In this case, the fixtures are [stored as JSON files](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/tests/sample-data) in the repository, and contain real life responses received from the API.

The [`FakeRothAPI`](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/tests/fake_client.py) returns the sample data for each of the methods defined in the abstract class. The following is a partial extract from the fake client code:

```python
# ...
from pytouchlinesl.client import BaseClient
from pytouchlinesl.client.models import AccountModuleModel, ModuleModel

data_dir = Path(os.path.realpath(__file__)).parent / "sample-data"


class FakeRothAPI(BaseClient):
    def __init__(self):
        self._user_id = 123456789
        self._token = "deadbeef"

    async def user_id(self) -> int:
        return self._user_id

    async def authenticated(self) -> bool:
        return True if self._token else False

    async def modules(self) -> list[AccountModuleModel]:
        with open(data_dir / "modules.json", "r") as f:
            data = json.load(f)

        return [AccountModuleModel(**m) for m in data]

#...
```

From there, I defined a [number of test fixtures](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/tests/conftest.py) using `pytest`'s `@pytest.fixture` decorator, which provide an initialised `TouchlineSL` instance, backed by the fake client, a `Module` instance, and a `Zone` instance.

From there, the [tests](https://github.com/jnsgruk/pytouchlinesl/tree/a0e02f19f95edc01093f45e85705dbff44da949a/tests) are fairly simple. Beyond injecting the fake client, there is no mocking required, which in my opinion keeps the test code much easier to read and understand. It also means I could focus more of my energy on validating the logic I was testing, rather than worrying about how patching might interact with the rest of the code. I've felt bad about mocking for years, and I think the clearest articulation I've seen is ["Don't Mock What You Don't Own" in 5 Minutes](https://hynek.me/articles/what-to-mock-in-5-mins/).

One aspect of the test suite I don't love is the use of `time.sleep` in [certain tests](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/tests/test_module.py#L42). This is because my caching implementation relies on reading a timestamp to decide on whether it should refresh data. In general I steer away from sleeps in tests, as they're often used to mask an underlying non-determinism, but in this case it felt a reasonable trade-off, given that I'm testing a time-based functionality.

### CI

I wanted to ensure that any pull requests were tested, and that they conform to the project's formatting/linting rules. Since the project is hosted on Github, I used Github Actions for this. The pipeline for this project is pretty simple, it lints and formats the code with `ruff` failing if any files were changed by the formatter or any of the linting rules were violated.

Finally, `uv` [is used](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/.github/workflows/_test.yaml#L54-L56) to run `pytest` across a [matrix of supported Python versions](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/.github/workflows/_test.yaml#L30-L35). I could have used `uv` to handle the download and install of different Python versions too, but the `setup-python` actions has served me perfectly well in the past.

### Publishing

Publishing is taken care of in CI. I don't like having to remember the magic incantation for building, authenticating and publishing locally. I want the process to be as consistent and as transparent as possible for the people consuming the project.

What was new to me this time was publishing to PyPI with a "Trusted Publisher" setup. To quote their [docs](https://docs.pypi.org/trusted-publishers/):

> "Trusted publishing" is our term for using the OpenID Connect (OIDC) standard to exchange short-lived identity tokens between a trusted third-party service and PyPI. This method can be used in automated environments and eliminates the need to use manually generated API tokens to authenticate with PyPI when publishing.

Rather than setting up Github Actions to hold an API token in a Secret, there is some automation that links a Github project to a PyPI project. The project doesn't even have to be previously published on PyPI to get started, and [new projects can be configured](https://docs.pypi.org/trusted-publishers/creating-a-project-through-oidc/) as "Pending", then published to for the first time from your CI system of choice 🚀.

I [configured Github Actions](https://github.com/jnsgruk/pytouchlinesl/blob/a0e02f19f95edc01093f45e85705dbff44da949a/.github/workflows/publish.yaml) to trigger the release of `pytouchlinesl` on new tags being pushed:

```yaml
# ...
publish:
  name: Build and Publish to PyPI
  runs-on: ubuntu-latest
  needs:
    - tests

  # Trusted publisher setup for PyPI
  environment:
    name: pypi
    url: https://pypi.org/p/pytouchlinesl
  permissions:
    id-token: write

  steps:
    - name: Checkout the code
      uses: actions/checkout@v4

    - name: Install `uv`
      run: |
        curl -LsSf https://astral.sh/uv/install.sh | sh

    - name: Build the package
      run: |
        uvx --from build pyproject-build --installer uv

    - name: Publish to PyPi
        uses: pypa/gh-action-pypi-publish@v1.10.0
```

## Contributing to `nixpkgs`

Finally, my Home Assistant server runs NixOS, so in order for the integration to be packaged easily in the future, I created a small PR to include `pytouchlinesl` in `nixpkgs`. The [original PR](https://github.com/NixOS/nixpkgs/pull/336794) went through pretty quickly - thanks to [@drupol](https://github.com/drupol) for the fast review!

Since then I've made a couple of minor version bumps to the library as I discovered small issues when building the integration, but the [final derivation](https://github.com/NixOS/nixpkgs/blob/1355a0cbfeac61d785b7183c0caaec1f97361b43/pkgs/development/python-modules/pytouchlinesl/default.nix) is quite compact (see below). The Python build tooling in Nix is quite mature at this point, and I gained a fair bit of experience using it when packaging `snapcraft` and `charmcraft`.

```nix
#...

buildPythonPackage rec {
  pname = "pytouchlinesl";
  version = "0.1.5";
  pyproject = true;

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "jnsgruk";
    repo = "pytouchlinesl";
    rev = "refs/tags/${version}";
    hash = "sha256-kdLMuxA1Ig85mH7s9rlmVjEsItXxRlDA1JTFasnJogg=";
  };

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    pydantic
  ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-asyncio
  ];

  pythonImportsCheck = [ "pytouchlinesl" ];

  # ...
}
```

## Summary

And that concludes the first part of this series! Hopefully you found this useful - I've learned a lot from people over the years by understanding how they approach problems, so I thought I'd post my methodology here in case it helps anyone refine their process.

I'm certainly no Python expert, so if you've spotted a mistake or you think I'm wrong, get in touch.

In the next post, I'll cover writing the Home Assistant integration, and contributing it to Home Assistant.
