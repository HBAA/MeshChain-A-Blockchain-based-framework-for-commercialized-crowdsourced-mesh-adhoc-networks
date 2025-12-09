
contract MeshServiceManager {
    
    struct Decision{
        address validatorAdd;

        uint32 routingCost; //routing cost of router in Wei/MB * 10^6

        uint64 BytesFw; // total of bytes forwarded.

        // uint64 avgDelay; //average delay in the buffer. 

        uint64 percPacketsFw; // the average number of packets rcvd and then forwarded
    }


     struct headDecision2{
        address validatorAdd;

        address selector; 

        uint32 headCost; //routing cost of router in Wei/MB * 10^6

        uint64 serveTime; //average delay in the buffer. 
    }


    struct Request {
        uint32 requestID;
        address destination;
        uint64 bytesRequested;
        bytes16 user_ip;
        bytes16 dest_ip;
    }

    uint32 requestsID = 1;
    
    mapping(address => uint256) public deposits;
    mapping(uint64 => Decision[]) routerDecisions; // a unique identifier created by combining the requestID and routerID to the set of decisions. 
    mapping(address => mapping(uint32 => Request)) public userRequests; //map the requester Address to the list of requests

    mapping(uint64 => headDecision2[]) public headDecisions2;

    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event DecisionAdded(address indexed source, address indexed router, address validatorAdd, uint256 percBytesFw, uint256 avgDelay);
    event Payment(address indexed source, address indexed router, uint256 amountTransferred);
    event RequestAdded(address indexed user, address indexed destination, uint64 bytesRequested, uint32 indexed requestId, bytes32 _sourceIP, bytes32 _destIP);
    event ServiceEnded(address indexed user, uint32 indexed requestId, bytes16 _sourceIP, bytes16 _destIP);
    event headPayment(address indexed _headAdd, uint256 pay);


    function getRouterDecisions(uint32 _routerID, uint32 _requestID) public view returns (Decision[] memory){
            uint64 _combinedID = (uint64(_routerID) << 32) | uint64(_requestID);
            return routerDecisions[_combinedID];
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        deposits[msg.sender] += msg.value;
        // emit Deposit(msg.sender, msg.value);
    }


    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }



// This function implements adding a decision on one head serving one selector.
    function addHeadDecision2(uint32 _headID, uint32 _selID, address _headAdd, address _validatorAdd, uint32 _hcost, uint64 _serveTime, address _selector) public {

        uint64 _combinedID = (uint64(_headID) << 32) | uint64(_selID);

       //Create decision variable and add it to the mapping 
       headDecision2 memory newDecision = headDecision2(_validatorAdd, _selector, _hcost, _serveTime);
       headDecisions2[_combinedID].push(newDecision);


         // Check if the number of decisions for the flow is 3
        if (headDecisions2[_combinedID].length == 3) {
            // Call the payment function
            calculateHeadPayment2(_headAdd,_selector, _combinedID);

            //clear the decision array
            delete headDecisions2[_combinedID];

        }
    }



    function calculateHeadPayment2(address _headAdd, address selector, uint64 _combinedID) internal{
        
       (uint64 Time, uint32 hCost) = aggregateHead2(_combinedID);

            uint64 pay =  Time * hCost ;

            require(deposits[selector] >= pay, "Insufficient balance for payment"); // Ensure source has enough balance

            deposits[selector] -= pay; // Deduct payment amount from source's deposit
            deposits[_headAdd] += pay; // Add payment amount to router's deposit
                
    }


struct VoteCounter {
    uint64 value;
    uint16 count;
}


function aggregateHead2(uint64 _combinedID) internal view returns (uint64, uint32) {
    // Compute votes for each metric using separate functions
    uint64 maxServeTime = getMajorityVoteServeTime(_combinedID);
    uint32 maxHeadCost = getMajorityVoteHeadCost(_combinedID);

    // Return the majority-voted values
    return (maxServeTime, maxHeadCost);
}

// Internal function to compute the majority vote for serveTime
function getMajorityVoteServeTime(uint64 _combinedID) internal view returns (uint64) {
    VoteCounter[] memory counters = new VoteCounter[](headDecisions2[_combinedID].length);
    uint16 counterSize = 0;

    uint64 maxValue = 0;
    uint16 maxCount = 0;

    for (uint16 i = 0; i < headDecisions2[_combinedID].length; i++) {
        uint64 value = headDecisions2[_combinedID][i].serveTime;

        bool found = false;
        for (uint16 j = 0; j < counterSize; j++) {
            if (counters[j].value == value) {
                counters[j].count++;
                found = true;

                if (counters[j].count > maxCount) {
                    maxCount = counters[j].count;
                    maxValue = value;
                }
                break;
            }
        }

        if (!found) {
            counters[counterSize] = VoteCounter({ value: value, count: 1 });
            counterSize++;

            if (1 > maxCount) {
                maxCount = 1;
                maxValue = value;
            }
        }
    }

    return maxValue;
}

// Internal function to compute the majority vote for headCost
function getMajorityVoteHeadCost(uint64 _combinedID) internal view returns (uint32) {
    VoteCounter[] memory counters = new VoteCounter[](headDecisions2[_combinedID].length);
    uint16 counterSize = 0;

    uint32 maxValue = 0;
    uint16 maxCount = 0;

    for (uint16 i = 0; i < headDecisions2[_combinedID].length; i++) {
        uint32 value = headDecisions2[_combinedID][i].headCost;

        bool found = false;
        for (uint16 j = 0; j < counterSize; j++) {
            if (counters[j].value == value) {
                counters[j].count++;
                found = true;

                if (counters[j].count > maxCount) {
                    maxCount = counters[j].count;
                    maxValue = value;
                }
                break;
            }
        }

        if (!found) {
            counters[counterSize] = VoteCounter({ value: value, count: 1 });
            counterSize++;

            if (1 > maxCount) {
                maxCount = 1;
                maxValue = value;
            }
        }
    }

    return maxValue;
}


    // Function to add a decision for a source and destination address
    function addDecision(uint32 _routerID, uint32 _requestID, address _routerAdd, address _sourceAdd, address _validatorAdd, uint32 _rcost, uint64 _percBytesFw, uint64 _percPacketsFw) public{
    
       //merge the router ID and request ID to the 32 bit identifier
       uint64 _combinedID = (uint64(_routerID) << 32) | uint64(_requestID);

       //create decision variable and add it to the mapping 
       Decision[] storage decisions = routerDecisions[_combinedID];

        decisions.push(
            Decision(_validatorAdd, _rcost, _percBytesFw, _percPacketsFw)
        );

         // Check if the number of decisions for the flow is 3
        if (decisions.length == 3) {
            // Call the payment function
            calculatePayment(_sourceAdd, _routerAdd, _combinedID);
            //clear the decision array
            delete routerDecisions[_combinedID];
        }
    }


     // Function to calculate payment and transfer funds from source to router
    function calculatePayment(address _sourceAdd, address _routerAdd, uint64 _combinedID) internal {

        (uint64 bytesTransmitted, uint64 percpackets, uint32 rcost) = aggregate(_combinedID); // Call aggregate to get bytes transmitted
        uint256 amount = (bytesTransmitted * rcost * percpackets)/1000000; // Calculate payment amount

        require(deposits[_sourceAdd] >= amount, "Insufficient balance for payment"); // Ensure source has enough balance

        deposits[_sourceAdd] -= amount; // Deduct payment amount from source's deposit
        deposits[_routerAdd] += amount; // Add payment amount to router's deposit
    }


function aggregate(uint64 _combinedID) internal view returns (uint64, uint64, uint32) {
    // Compute votes for each metric using separate functions
    uint64 maxBytesFw = getMajorityVoteBytesFw(_combinedID);
    uint64 maxPercFw = getMajorityVotePercFw(_combinedID);
    uint32 maxRoutingCost = getMajorityVoteRoutingCost(_combinedID);

    // Return the majority-voted values
    return (maxBytesFw, maxPercFw, maxRoutingCost);
}

// Internal function to compute the majority vote for BytesFw
function getMajorityVoteBytesFw(uint64 _combinedID) internal view returns (uint64) {
    VoteCounter[] memory counters = new VoteCounter[](routerDecisions[_combinedID].length);
    uint16 counterSize = 0;

    uint64 maxValue = 0;
    uint16 maxCount = 0;

    for (uint16 i = 0; i < routerDecisions[_combinedID].length; i++) {
        uint64 value = routerDecisions[_combinedID][i].BytesFw;

        bool found = false;
        for (uint16 j = 0; j < counterSize; j++) {
            if (counters[j].value == value) {
                counters[j].count++;
                found = true;

                if (counters[j].count > maxCount) {
                    maxCount = counters[j].count;
                    maxValue = value;
                }
                break;
            }
        }

        if (!found) {
            counters[counterSize] = VoteCounter({ value: value, count: 1 });
            counterSize++;

            if (1 > maxCount) {
                maxCount = 1;
                maxValue = value;
            }
        }
    }

    return maxValue;
}

// Internal function to compute the majority vote for PercPacketsFw
function getMajorityVotePercFw(uint64 _combinedID) internal view returns (uint64) {
    VoteCounter[] memory counters = new VoteCounter[](routerDecisions[_combinedID].length);
    uint16 counterSize = 0;

    uint64 maxValue = 0;
    uint16 maxCount = 0;

    for (uint16 i = 0; i < routerDecisions[_combinedID].length; i++) {
        uint64 value = routerDecisions[_combinedID][i].percPacketsFw;

        bool found = false;
        for (uint16 j = 0; j < counterSize; j++) {
            if (counters[j].value == value) {
                counters[j].count++;
                found = true;

                if (counters[j].count > maxCount) {
                    maxCount = counters[j].count;
                    maxValue = value;
                }
                break;
            }
        }

        if (!found) {
            counters[counterSize] = VoteCounter({ value: value, count: 1 });
            counterSize++;

            if (1 > maxCount) {
                maxCount = 1;
                maxValue = value;
            }
        }
    }

    return maxValue;
}

// Internal function to compute the majority vote for RoutingCost
function getMajorityVoteRoutingCost(uint64 _combinedID) internal view returns (uint32) {
    VoteCounter[] memory counters = new VoteCounter[](routerDecisions[_combinedID].length);
    uint16 counterSize = 0;

    uint32 maxValue = 0;
    uint16 maxCount = 0;

    for (uint16 i = 0; i < routerDecisions[_combinedID].length; i++) {
        uint32 value = routerDecisions[_combinedID][i].routingCost;

        bool found = false;
        for (uint16 j = 0; j < counterSize; j++) {
            if (counters[j].value == value) {
                counters[j].count++;
                found = true;

                if (counters[j].count > maxCount) {
                    maxCount = counters[j].count;
                    maxValue = value;
                }
                break;
            }
        }

        if (!found) {
            counters[counterSize] = VoteCounter({ value: value, count: 1 });
            counterSize++;

            if (1 > maxCount) {
                maxCount = 1;
                maxValue = value;
            }
        }
    }

    return maxValue;
}


    // Function to check the balance of an account in the smart contract
    function getBalance(address account) public view returns (uint256) {
        return deposits[account];
    }


    function requestService(address _destination, uint64 _bytesRequested, bytes16 _sourceIP, bytes16 _destIP) public returns (uint32){
   
        require(deposits[msg.sender] >= _bytesRequested * 200, "Insufficient Balance");

        uint32 _requestID = requestsID++;

        userRequests[msg.sender][_requestID] = Request(
            _requestID, 
            _destination, 
            _bytesRequested, 
            _sourceIP, 
            _destIP
        );

        emit RequestAdded(msg.sender, _destination, _bytesRequested,_requestID,_sourceIP,_destIP);

        return _requestID;
    }


    function endService(uint32 requestId) public {
        require(userRequests[msg.sender][requestId].requestID != 0, "Invalid request ID");

        bytes16 _sourceIP = userRequests[msg.sender][requestId].user_ip;
        bytes16 _destIP = userRequests[msg.sender][requestId].dest_ip;

        // Delete the request from storage
        delete userRequests[msg.sender][requestId];

        emit ServiceEnded(msg.sender, requestId, _sourceIP, _destIP);
    }
    // Function to get a specific request by requestId
    function getRequestById(uint32 requestId) public view returns (Request memory) {
        require(userRequests[msg.sender][requestId].requestID != 0, "Request not found");
        return userRequests[msg.sender][requestId];
    }

}
