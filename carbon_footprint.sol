// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/utils/math/SafeMath.sol";

contract CampusCarbonFootprint is ReentrancyGuard {
    using SafeMath for uint256;

    struct User {
        uint256 totalEmission;
        mapping(string => uint256) activityEmissions;
        bool rewarded;
        bool exists;
    }

    mapping(address => User) private users;
    mapping(string => uint256) private emissionFactors;
    string[] private activityTypes;
    mapping(address => bool) public authorizedUsers;

    address public owner;
    uint256 public rewardAmount = 1 ether;
    address[] private allUserAddresses; 

    event ActivityAdded(string activityType, uint256 factor);
    event ActivityRecorded(address indexed user, string activityType, uint256 amount);
    event UserAuthorized(address indexed user);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event RewardDistributed(address indexed user, uint256 rewardAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender], "Not authorized to record activities.");
        _;
    }

    constructor() {
        owner = msg.sender;
        addActivityType("schoolBus", 16000);     
        addActivityType("electricBike", 9600);   
        addActivityType("electricCar", 120000);  
        addActivityType("fuelCar", 207000);  //mg/km    
        addActivityType("water", 168);  //mg/kg      
        addActivityType("electricity", 997200); //mg/kwh 
        addActivityType("paper", 2750000);//mg/kg
        addActivityType("beef", 70600); //mg/g
        addActivityType("goat meat", 39700);  //mg/g     
        addActivityType("mussels", 26900);  //mg/g
        addActivityType("cheese", 23900);  //mg/g
        addActivityType("fish", 13600);  //mg/g
        addActivityType("pork", 12300);  //mg/g
        addActivityType("poultry", 9900);  //mg/g
        addActivityType("egg", 4700);  //mg/g
        addActivityType("Rice", 3600);  //mg/g 
        addActivityType("cereals", 3600);  //mg/g
        addActivityType("milk", 3200);  //mg/g  
        addActivityType("tofu", 3200);  //mg/g
        addActivityType("legumes", 2000);  //mg/g
        addActivityType("Bread", 1600);  //mg/g
        addActivityType("pasta", 1600);  //mg/g
        addActivityType("fruit", 900);  //mg/g
        addActivityType("vegetables", 700);  //mg/g
        addActivityType("nuts", 400);  //mg/g
    }

    function addActivityType(string memory activityType, uint256 factor) public onlyOwner {
        require(emissionFactors[activityType] == 0, "Activity type already exists.");
        emissionFactors[activityType] = factor;
        activityTypes.push(activityType);
        emit ActivityAdded(activityType, factor);
    }

    function authorizeUser(address user) external onlyOwner {
        authorizedUsers[user] = true;
        users[user].exists = true;
        allUserAddresses.push(user); 
        emit UserAuthorized(user);
    }

    function recordActivity(string memory activityType, uint256 amount, address[] calldata participants) external onlyAuthorized {
        require(emissionFactors[activityType] != 0, "Activity type not registered.");
        require(amount > 0, "Amount must be greater than zero.");

        uint256 totalParticipants = participants.length;
        require(totalParticipants > 0, "At least one participant required.");

        bool isSenderIncluded = false;
        for (uint256 i = 0; i < totalParticipants; i++) {
            require(users[participants[i]].exists, "Participant not registered.");
            if(participants[i] == msg.sender) {
                isSenderIncluded = true;
            }
        }
        require(isSenderIncluded, "Sender must be a participant.");

        uint256 totalEmission = amount.mul(emissionFactors[activityType]).div(1000);
        uint256 emissionPerParticipant = totalEmission.div(totalParticipants);

        for (uint256 i = 0; i < totalParticipants; i++) {
            users[participants[i]].totalEmission = users[participants[i]].totalEmission.add(emissionPerParticipant);
            users[participants[i]].activityEmissions[activityType] = users[participants[i]].activityEmissions[activityType].add(emissionPerParticipant);
            emit ActivityRecorded(participants[i], activityType, emissionPerParticipant);
        }
    }
    function getTotalEmissions() external view onlyOwner returns (uint256 totalEmission, string[] memory allActivityTypes, uint256[] memory totalActivityEmissions) {
        // Count the activity types
        uint256 activityCount = activityTypes.length;

        allActivityTypes = new string[](activityCount);
        totalActivityEmissions = new uint256[](activityCount);

        // Initialize activity types array
        for (uint256 i = 0; i < activityCount; i++) {
            allActivityTypes[i] = activityTypes[i];
            totalActivityEmissions[i] = 0; // Initialize the array element
        }

        // Iterate over all users to sum up total emissions and activity-specific emissions
        for (uint256 i = 0; i < allUserAddresses.length; i++) {
            address userAddress = allUserAddresses[i];
            totalEmission = totalEmission.add(users[userAddress].totalEmission);
            for (uint256 j = 0; j < activityCount; j++) {
                totalActivityEmissions[j] = totalActivityEmissions[j].add(users[userAddress].activityEmissions[allActivityTypes[j]]);
            }
        }
    }
    function getAllUsers() public view returns (address[] memory) {
        return allUserAddresses;
    }
    function getEmission(address userAddress) public view returns (uint256 total, string[] memory activities, uint256[] memory emissions) {
        require(users[userAddress].exists, "User not registered.");
        require(msg.sender == owner || msg.sender == userAddress, "Not authorized to view this user's emissions.");

        total = users[userAddress].totalEmission;
        uint256 activityCount;

        for (uint256 i = 0; i < activityTypes.length; i++) {
            if (users[userAddress].activityEmissions[activityTypes[i]] > 0) {
                activityCount++;
            }
        }

        activities = new string[](activityCount);
        emissions = new uint256[](activityCount);

        uint256 counter;
        for (uint256 i = 0; i < activityTypes.length; i++) {
            if (users[userAddress].activityEmissions[activityTypes[i]] > 0) {
                activities[counter] = activityTypes[i];
                emissions[counter] = users[userAddress].activityEmissions[activityTypes[i]];
                counter++;
            }
        }
    }

    function distributeRewards() external onlyOwner nonReentrant {
        require(allUserAddresses.length > 0, "No users to reward.");

        address lowestEmissionUser;
        uint256 lowestEmission = type(uint256).max;

        for (uint256 i = 0; i < allUserAddresses.length; i++) {
            if (users[allUserAddresses[i]].totalEmission < lowestEmission && !users[allUserAddresses[i]].rewarded) {
                lowestEmissionUser = allUserAddresses[i];
                lowestEmission = users[allUserAddresses[i]].totalEmission;
            }
        }

        require(lowestEmissionUser != address(0), "No eligible users to reward.");
        payable(lowestEmissionUser).transfer(rewardAmount);
        users[lowestEmissionUser].rewarded = true;
        emit RewardDistributed(lowestEmissionUser, rewardAmount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
