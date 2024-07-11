# OLAS Dev Academy - Session IV Homework

The solutions on this repository are based on [hello-world v0.1.8](https://github.com/valory-xyz/hello-world/releases/tag/v0.1.8) (although they are likely valid for other versions).

- Clone the repository `https://github.com/valory-xyz/hello-world/`
    `git clone git@github.com:valory-xyz/hello-world.git`
    `git checkout v0.1.8`

For convenience, we provide the script `run_hello_world_service.sh`, which is in charge of executing a number of required steps to run the service after modifying the source code. Make sure to copy it in the root of your cloned repository. You can examine it to get familiar with the framework CLI.

## Exercise 1

- Create a new configuration parameter in the Skill/Agent/Service which is the "owner" Ethereum address.
- Access the configuration parameter through the shared state.
- Print the address in the output: "Hello world! The owner’s address is 0x000..."

### Solution

1. Edit the file `./packages/valory/skills/hello_world_abci/skill.yaml` and add a new key called `my_owner_address` within `models.params.args` as follows:

    ```yaml
    my_owner_address: '0x0000000000000000000000000000000000000000'
    ```

2. Edit the file `./packages/valory/agents/hello_world/aea-config.yaml` and add a new key called `my_owner_address` within `models.params.args` as follows:

    ```yaml
    my_owner_address: ${str:'0x0000000000000000000000000000000000000000'}
    ```

3. Edit the file `./packages/valory/services/hello_world/service.yaml` and add a new key called `my_owner_address` within `models.params.args` as follows (4 times, one per agent):

    ```yaml
    my_owner_address: ${MY_OWNER_ADDRESS_0:str:'0x0000000000000000000000000000000000000000'}

    my_owner_address: ${MY_OWNER_ADDRESS_1:str:'0x0000000000000000000000000000000000000000'}

    my_owner_address: ${MY_OWNER_ADDRESS_2:str:'0x0000000000000000000000000000000000000000'}

    my_owner_address: ${MY_OWNER_ADDRESS_3:str:'0x0000000000000000000000000000000000000000'}
    ```

4. Edit the file `./packages/valory/skills/hello_world_abci/models.py` and add the following code within the method `__init__` of `HelloWorldParams`:

    ```python
    self.my_owner_address: str = self._ensure("my_owner_address", kwargs, str)
    ```

5. Edit the file `./packages/valory/skills/hello_world_abci/behaviours.py` and add the following code within the method `async_act` of `PrintMessageBehaviour`:

    ```python
    print(f"I am an agent. My owner address is: {self.params.my_owner_address}")
    ```

6. Optionally, override the parameters as environment variables before running the service (you can also include them in the script `run_hello_world_service.sh`):

    ```bash
    export MY_OWNER_ADDRESS_0='0x0123000000000000000000000000000000000000'
    export MY_OWNER_ADDRESS_1='0x0123000000000000000000000000000000000001'
    export MY_OWNER_ADDRESS_2='0x0123000000000000000000000000000000000002'
    export MY_OWNER_ADDRESS_3='0x0123000000000000000000000000000000000003'
    ```

7. Run the service and examine the logs. You can use the script `run_hello_world_service.sh`. In case you have not yet created a virtual environment, you will first need to execute:

    ```bash
    pipenv shell
    pipenv lock
    pipenv install --dev
    ```

## Exercise 2

Implement a new state on the FSM (Round + Behaviour) that prints to screen how many times the service has executed the `PrintMessageRound`. The round must be placed after the `PrintMessageRound`. You need to:

- define a new variable in the `SynchronizedData` called `print_count`
- define an appropriate payload to store the updated count
- define a new Round that subclasses `CollectSameUntilThresholdRound`
- define the associated Behaviour to read the current value of `print_count` on the `SynchronizedData`, increase it by 1, and send the result in the payload. It must also print to screen `The message has been printed {print_count} times`. If configured correctly, the Round will pick the payload and update automatically the `print_count` value on the `SynchronizedData`.

### Solution

1. Edit the file `packages/valory/skills/hello_world_abci/payloads.py` and add a new Payload:

    ```python
    @dataclass(frozen=True)
    class PrintCountPayload(BaseTxPayload):
        """Represent a transaction payload of type 'randomness'."""

        print_count: int
    ```

2. Edit the file `packages/valory/skills/hello_world_abci/rounds.py` and implement the following changes:

    - Import the `PrintCountPayload` and the `typing.FrozenSet` classes.

    - Add the `print_count` property to the ``SynchronizedData`:

        ```python
        @property
        def print_count(self) -> int:
            """Get the print count."""

            return cast(int, self.db.get("print_count", 0))
        ```

    - Add a new round `PrintCountRound`:
  
        ```python
        class PrintCountRound(
            CollectSameUntilThresholdRound, HelloWorldABCIAbstractRound
        ):
            """A round for counting printed messages."""

            payload_class = PrintCountPayload
            synchronized_data_class = SynchronizedData
            done_event = Event.DONE
            none_event = Event.NONE
            no_majority_event = Event.NO_MAJORITY
            collection_key = get_name(SynchronizedData.participant_to_selection)
            selection_key = get_name(SynchronizedData.print_count)
        ```

    - "Rewire" the class `HelloWorldAbciApp` to include this new round:

        ```python
        PrintMessageRound: {
            Event.DONE: PrintCountRound,                # Rewired
            Event.ROUND_TIMEOUT: RegistrationRound,
        },
        PrintCountRound: {                              # Added
            Event.DONE: ResetAndPauseRound,             # Added
            Event.NONE: RegistrationRound,              # Added
            Event.ROUND_TIMEOUT: RegistrationRound,     # Added
        },
        ```

    - Make the `print_count` property persistent across different periods on the ``HelloWorldAbciApp`. If this is not included, the value of `print_count` will be reset after each cycle:

        ```python
        cross_period_persisted_keys: FrozenSet[str] = frozenset(
            [get_name(SynchronizedData.print_count)]
        )
        ```

3. Edit the file `packages/valory/skills/hello_world_abci/behaviours.py` and implement the following changes:

    - Import the `PrintCountPayload` and `PrintCountRound` classes.

    - Add a new behaviour `PrintCountBehaviour`:
  
        ```python
        class PrintCountBehaviour(HelloWorldABCIBaseBehaviour, ABC):
            """Prints the print count."""

            matching_round = PrintCountRound

            def async_act(self) -> Generator:
                """Do the action."""

                current_count = self.synchronized_data.print_count
                updated_count = current_count + 1
                print(f"The message has been printed {updated_count} times.")
                payload = PrintCountPayload(self.context.agent_address, updated_count)

                yield from self.send_a2a_transaction(payload)
                yield from self.wait_until_round_end()

                self.set_done()
        ```

    - Add the behaviour reference to the `HelloWorldRoundBehaviour`:
  
        ```python
        behaviours: Set[Type[BaseBehaviour]] = {
            RegistrationBehaviour,  # type: ignore
            CollectRandomnessBehaviour,  # type: ignore
            SelectKeeperBehaviour,  # type: ignore
            PrintMessageBehaviour,  # type: ignore
            PrintCountBehaviour,  # type: ignore     <-- Added
            ResetAndPauseBehaviour,  # type: ignore
        }
        ```

4. Run the service and examine the logs. You can use the script `run_hello_world_service.sh`. In case you have not yet created a virtual environment, you will first need to execute:

    ```bash
    pipenv shell
    pipenv lock
    pipenv install --dev
    ```
