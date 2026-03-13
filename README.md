## FundMe (Solidity + Foundry)

**FundMe** — это минималистичный, но реалистичный пример децентрализованного краудфандинга на Ethereum.  
Проект показывает, как с помощью Solidity, Foundry и Chainlink реализовать контракт, который:

- **принимает средства** в ETH;
- **проверяет минимальный вклад в USD** через Chainlink price feed;
- **позволяет только владельцу контракта** забирать собранные средства;
- демонстрирует **газ‑оптимизированные** паттерны вывода.

Основан на учебном курсе по разработке смарт‑контрактов от Cyfrin.

---

## Основная идея

Традиционные краудфандинговые платформы централизованы и контролируют средства пользователей.  
**FundMe** реализует простую децентрализованную модель:

- любой пользователь может профинансировать контракт ETH;
- вклад принимается только если его стоимость \(\ge 5\) USD (по Chainlink ETH/USD);
- владелец контракта может вывести все накопленные средства;
- вклады и список вкладчиков отслеживаются в состоянии контракта.

---

## Архитектура проекта

- `src/FundMe.sol`  
  - основной смарт‑контракт;  
  - хранит:
    - `s_addressToAmountFunded` — mapping адрес → сумма вклада;
    - `s_funders` — массив всех адресов вкладчиков;  
  - ключевые функции:
    - `fund()` — внести средства (с проверкой min USD);
    - `withdraw()` — стандартный вывод средств владельцем;
    - `cheaperWithdraw()` — газ‑оптимизированный вывод;
    - `getAddressToAmountFunded`, `getFunder`, `getOwner`, `getVersion`;  
  - `MINIMUM_USD = 5e18` — минимальный вклад в USD (через Chainlink price feed).

- `src/PriceConverter.sol`  
  - библиотека для работы с Chainlink `AggregatorV3Interface`;  
  - `getPrice()` — получает текущую цену ETH/USD;  
  - `getConversionRate()` — пересчитывает `ethAmount` в USD эквивалент (18 знаков).

- `script/HelperConfig.s.sol`  
  - конфиг для разных сетей:
    - для Sepolia использует реальный ETH/USD price feed `0x694AA1769357215DE4FAC081bf1f309aDC325306`;
    - для локальной сети (Anvil) разворачивает `MockV3Aggregator` и возвращает его адрес;  
  - выбирает конфигурацию по `block.chainid`.

- `script/DeployFundMe.s.sol`  
  - скрипт деплоя `FundMe`;  
  - берёт активный конфиг из `HelperConfig`;  
  - вызывает конструктор `FundMe(priceFeed)`.

- `script/Interactions.s.sol`  
  - `FundFundMe` — скрипт, который:
    - находит **последний деплой** контракта `FundMe` через `DevOpsTools.get_most_recent_deployment`;
    - вызывает `fund{value: 0.1 ether}()` на этом контракте;
  - `WithdrawFundMe` — скрипт, который:
    - находит последний деплой `FundMe`;
    - вызывает `withdraw()` для вывода баланса владельцу.

- `test/FundMe.t.sol`  
  - юнит‑тесты для контракта `FundMe`:
    - проверка `MINIMUM_USD`;
    - проверка владельца;
    - проверка версии price feed;
    - провал транзакции без достаточного ETH;
    - обновление структуры хранения вкладов;
    - ограничение права вывода только для владельца;
    - сценарии вывода с одним и множеством вкладчиков (оба варианта: `withdraw` и `cheaperWithdraw`).

- `test/Interactions.t.sol`  
  - интеграционный тест:
    - деплой `FundMe`;
    - пользователь (Karina) вносит `SEND_VALUE = 0.1 ether`;
    - владелец выводит средства;
    - проверяется корректность изменения балансов пользователя, владельца и контракта.

- `Makefile`  
  - `build` — `forge build`;  
  - `deploy-sepolia` — деплой в сеть Sepolia через `forge script` с верификацией на Etherscan.

---

## Технологический стек

- **Solidity 0.8.x** — язык смарт‑контрактов.  
- **Foundry** (`forge`, `cast`, `anvil`) — сборка, тестирование, локальный блокчейн.  
- **Chainlink** — децентрализованные прайс‑фиды ETH/USD.  
- **foundry-devops** — утилиты для работы с последними деплоями.  
- **Makefile** — удобные команды для сборки и деплоя.

---

## Установка и настройка

1. **Клонировать репозиторий**

```bash
git clone <URL_ВАШЕГО_РЕПОЗИТОРИЯ> foundry-fund-me-f23
cd foundry-fund-me-f23
```

2. **Установить Foundry** (если ещё не установлен)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

3. **Установить зависимости (если нужно)**

```bash
forge install
```

4. **Создать и заполнить `.env`**

Пример содержимого:

```bash
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>
SEPOLIA_PRIVATE_KEY=0x<ВАШ_ПРИВАТНЫЙ_КЛЮЧ>
ETHERSCAN_API_KEY=<ВАШ_ETHERSCAN_API_KEY>
```

> **Важно:** не коммитьте приватный ключ в публичный репозиторий.

---

## Основные команды

Все команды выполняются из корня проекта.

- **Сборка контрактов**

```bash
forge build
# или
make build
```

- **Запуск тестов**

```bash
forge test
```

С более подробным выводом:

```bash
forge test -vvv
```

С отчётом по газу:

```bash
forge test --gas-report
```

---

## Локальная разработка (Anvil)

1. Запустить локальный узел:

```bash
anvil
```

2. В другом терминале (опционально настроив RPC URL через флаг `--rpc-url`):

```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <PRIVATE_KEY_IZ_ANVIL> \
  --broadcast -vvvv
```

`HelperConfig` автоматически:

- увидит, что сеть не Sepolia;
- задеплоит `MockV3Aggregator`;
- передаст его адрес в конструктор `FundMe`.

3. Далее можно использовать скрипты взаимодействия (`Interactions.s.sol`) аналогично (см. раздел ниже).

---

## Деплой в Sepolia

Для деплоя в Sepolia через `Makefile` (используется `.env`):

```bash
make deploy-sepolia
```

Эта команда:

- запускает `forge script script/DeployFundMe.s.sol:DeployFundMe`;
- использует `SEPOLIA_RPC_URL`, `SEPOLIA_PRIVATE_KEY`;
- включает `--broadcast` и `--verify` (верификация контракта на Etherscan);
- логирует подробный вывод (`-vvvv`).

---

## Взаимодействие с уже задеплоенным контрактом

Скрипты в `script/Interactions.s.sol` используют `DevOpsTools.get_most_recent_deployment`, поэтому:

1. Сначала сделайте деплой (`DeployFundMe`), чтобы появилась запись о последнем деплое контракта `FundMe` в текущей сети.
2. Затем можно вызывать:

- **Фандинг контракта (0.1 ETH)**

```bash
forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast -vvvv
```

- **Вывод средств владельцем**

```bash
forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast -vvvv
```

Скрипты:

- автоматически найдут последний деплой `FundMe` в указанной сети;
- проведут транзакции `fund()` или `withdraw()`.

---

## Поведение смарт‑контракта

- **Минимальный вклад**  
  `fund()` делает `require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)`.  
  При попытке отправить слишком маленькую сумму транзакция ревертится с сообщением `"You need to spend more ETH!"`.

- **Учёт вкладчиков**  
  При успешном `fund()`:
  - `s_addressToAmountFunded[msg.sender]` увеличивается на `msg.value`;
  - `msg.sender` добавляется в массив `s_funders`.

- **Вывод средств**  
  `withdraw()` и `cheaperWithdraw()`:

  - обнуляют вклады всех адресов в `s_addressToAmountFunded`;
  - очищают массив `s_funders`;
  - переводят весь баланс контракта на адрес владельца (`i_owner`) через низкоуровневый вызов `call`.

  Разница: `cheaperWithdraw()` копирует массив в память и тем самым экономит газ.

- **Fallback / receive**  
  Если на контракт отправили ETH напрямую (без вызова `fund()`), сработают `receive()` или `fallback()`, которые внутри вызывают `fund()` — таким образом логика минимального вклада и учёта вкладчиков сохраняется.

---

## Тестирование

В тестах используются утилиты Foundry (`vm`, `hoax`, `prank` и т.д.) для эмуляции:

- разных отправителей;
- начальных балансов;
- сценариев с несколькими вкладчиками;
- отказов по условиям.

Рекомендуется регулярно запускать:

```bash
forge test --gas-report
```

чтобы отслеживать влияние изменений на стоимость газа.

