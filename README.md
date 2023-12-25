# CampusCarbonFootprint Smart Contract

## Overview
`CampusCarbonFootprint` is a Solidity-based smart contract designed for tracking and managing carbon emissions for various campus-related activities. It utilizes the Ethereum blockchain to ensure transparency and integrity in the management of carbon footprint data.

## Features
- **Activity Tracking**: Tracks carbon emissions from various activities like transportation, electricity usage, food consumption, etc.
- **User Management**: Manages user registration and tracks individual carbon footprints.
- **Emission Factors**: Allows setting emission factors for different activities.
- **Rewards System**: Implements a system to reward users with the lowest carbon emissions.
- **Ownership Control**: Includes functionality for transferring contract ownership.

## Contract Functions
- `addActivityType(string, uint256)`: Adds a new activity type along with its emission factor.
- `authorizeUser(address)`: Authorizes a user to record activities.
- `recordActivity(string, uint256, address[])`: Records a new activity for specified participants.
- `getTotalEmissions()`: Retrieves total emissions data.
- `getAllUsers()`: Lists all registered users.
- `getEmission(address)`: Retrieves emission details for a specific user.
- `distributeRewards()`: Distributes rewards to the user with the lowest emissions.
- `transferOwnership(address)`: Transfers contract ownership.
- `setRewardAmount(uint256)`: Sets the reward amount.
- `getBalance()`: Gets the contract's current balance.



## Dependencies
- [ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/security/ReentrancyGuard.sol) from OpenZeppelin for reentrancy protection.
- [SafeMath](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/utils/math/SafeMath.sol) from OpenZeppelin for safe math operations.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
