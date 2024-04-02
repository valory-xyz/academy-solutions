# OLAS Dev Academy - Session III Homework

## Exercise 1

Run your first service.

### Solution

1. Ensure to satisfy system requirements.
2. Ensure to have some xDAI on Gnosis Chain.
3. Clone the repository `https://github.com/valory-xyz/trader-quickstart/`

    ```bash
    git clone git@github.com:valory-xyz/trader-quickstart.git
    ```

4. Execute main script: `run_service.sh`
5. Examine what the agent is doing:
   - Docker logs

        ```bash
        docker logs trader_abci_0 --follow 
        ```

   - FSM analysis tool

        ```bash
        cd trader; poetry run autonomy analyse logs --from-dir trader_service/abci_build/persistent_data/logs/ --agent aea_0 --fsm --reset-db; cd .. 
        ```

   - Trades summary script

        ```bash
        cd trader; poetry run python ../trades.py; cd ..
        ```

       also,

        ```bash
        cd trader; poetry run python ../report.py; cd ..
        ```

6. Investigate configuration parameters (`service.yaml`). Open the file `trader/packages/valory/services/trader/service.yaml` and take a look at the configuration parameters.
7. Restart your service:

    ```bash
    ./stop_service.sh
    ./run_service.sh
    ```
