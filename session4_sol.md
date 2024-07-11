# OLAS Dev Academy - Session 4 Homework

The solutions on this repository are based on [trader v0.12.8](https://github.com/valory-xyz/trader/releases/tag/v0.12.8).

- Clone the repository `https://github.com/valory-xyz/trader/`
    `git clone git@github.com:valory-xyz/trader.git`
    `git checkout v0.12.8`

## Exercise 1

- Review how betting strategies work.
- Review how they are configured in the .yaml config. files (skill, agent, service).
- Try to tune up some parameters of existing strategies.
- Write your own custom strategy.

### Solution

Betting strategies are dynamically loaded from IPFS. They are configured through the parameters

- `trading_strategy`: Strategy ID to use.
- `use_fallback_strategy`: Use a fallback strategy if `trading_strtegy` fails.
- `file_hash_to_strategies_json`: Mapping between IPFS hash and strategy ID.
- `strategies_kwargs`: Keyword arguments passed to the strategies.

which can be found on the files

- `packages/valory/skills/decision_maker_abci/skill.yaml`
- `packages/valory/agents/trader/aea-config.yaml`
- `packages/valory/services/trader/service.yaml`

The `service.yaml` also defines the environment variables which override the configuration values (e.g., environment variable `FILE_HASH_TO_STRATEGIES_JSON` will override `file_hash_to_strategies_json`).

To write your own strategy:

1. Set up the Poetry environment:

    ```bash
    poetry shell
    poetry install
    ```

2. Set up the framework and download the requires packages:

    ```bash
    autonomy init --reset --author valory --remote --ipfs --ipfs-node "/dns/registry.autonolas.tech/tcp/443/https"

    make clean
    AUTONOMY_VERSION=v$(autonomy --version | grep -oP '(?<=version\s)\S+')
    AEA_VERSION=v$(aea --version | grep -oP '(?<=version\s)\S+')
    autonomy packages sync --source valory-xyz/open-aea:$AEA_VERSION --source valory-xyz/open-autonomy:$AUTONOMY_VERSION --update-packages
    ```

3. Create a new strategy:

    ```bash
    mkdir -p packages/your_name/customs/fixed_amount_strategy
    ```

    Take a look how the following files are populated:

    ```text
    packages/your_name/__init__.py
    packages/your_name/customs/__init__.py

    packages/your_name/customs/fixed_amount_strategy/__init__.py
    packages/your_name/customs/fixed_amount_strategy/component.yaml
    packages/your_name/customs/fixed_amount_strategy/fixed_amount_strategy.py
    ```

4. Lock the packages, and push them to IPFS:

    ```bash
    autonomy packages lock
    autonomy push-all
    ```

    This will fix the hashes. Answer `dev` when asked `A new package found with package ID (custom, your_name/fixed_amount_strategy:0.1.0) Select package type (dev, third_party):`

5. Open the file `packages/packages.json` and note down the hash corresponding to `your_name/fixed_amount_strategy:0.1.0`.

6. Take a look at the file `trader-solutions/packages/valory/services/trader/service.yaml` and identify any strategy-related variable.

7. Export these environment variables pointing to your strategy:

    ```bash
    export TRADING_STRATEGY=fixed_amount_strategy
    export FILE_HASH_TO_STRATEGIES_JSON=[["bafybeictn4i5r2m4tmjagfubmc4xnxy6x4jezejv3udjsapudjyxfzeoeq",["fixed_amount_strategy"]],["bafybeihufqu2ra7vud4h6g2nwahx7mvdido7ff6prwnib2tdlc4np7dw24",["bet_amount_per_threshold"]],["bafybeif55cu7cf6znyma7kxus4wxa2doarhau2xmndo57iegshxorivwmq",["kelly_criterion"]]]

    ```

    Make sure to update the corresponding hash value by executing steps 4-7 when your code changes.

8. Run the service. We recommend that you push your working branch to Github, and clone the [trader-quickstart repository](https://github.com/valory-xyz/trader-quickstart) to run your service. You will need to edit these variables accordingly in the script `run_service.sh`:

    ```bash
    org_name=valory
    directory=trader
    service_repo=https://github.com/$org_name/$directory.git
    service_version=<trader_repo_working_branch>
    ```

    The configuration above assumes that you are pushing changes on a PR on the [trader repository](https://github.com/valory-xyz/trader). If you are using your own repository, please edit `org_name` and `directory` (repository) accordingly.
