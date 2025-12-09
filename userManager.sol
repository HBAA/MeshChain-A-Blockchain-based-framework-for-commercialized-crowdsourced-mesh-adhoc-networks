pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

contract MeshUsers{

    address admins; // admins of the system

    struct UserInfo{ // struct for the information of a given token

        uint32 userID;

        int reputation;

        int totalbytes; // the total bytes routed in the network

        int avgdelay; // The average delay as a router

        int totalrequest; // The total number of bytes requested
    }

    // mapping for users and their accessable devices
    mapping (address => UserInfo) public Users;

    uint32 IDcount= 1;

    constructor(){

        admins=msg.sender; //creator of contract is the first admin

    }


    function getUser(address s) public view returns(uint32,int,int,int){

      return (Users[s].userID, Users[s].reputation, Users[s].totalbytes, Users[s].avgdelay);

    }

    function getUserID(address s) public view returns(uint32){

      return (Users[s].userID);

    }

    function addUser(address _userAddress) public {

        Users[_userAddress].userID = IDcount++;

        Users[_userAddress].reputation = 50;

        Users[_userAddress].totalbytes = 0;

        Users[_userAddress].avgdelay = 0;

        emit UserAdded(_userAddress , Users[_userAddress].reputation);

    }


    event UserAdded(address user, int reputation);


    // delete a given user

    function delUser () public{ 

      delete Users[msg.sender];

      emit UserDeleted(msg.sender);

    }

    event UserDeleted(address a);

  
    function updateUserReputation(address u, int r, int t, int packetperc) public{ // t for +1 or -1 
        int repf = 10;
        if (packetperc > 80)
        {
            repf = 5;
        }
        //function for updating reputation
        if (t < 0)
        {
         Users[u].reputation =  Users[u].reputation + (t * (100-(packetperc))/10 * repf);
        }
        else{
                Users[u].reputation =  Users[u].reputation + 5;
        }

       emit ReputationUpdated(u,Users[u].reputation);

    }


    event ReputationUpdated(address _address, int rep);


    function updateUserTotalRequests(address u, int _totalRequests) public{

        //function for updating reputation
        Users[u].totalrequest += _totalRequests;

       emit TotalRequestsUpdated(u,Users[u].totalrequest);

    }

    event TotalRequestsUpdated(address _address, int _totalRequests);
    

    function updateUserTotalBytes(address u, int _totalbytes) public{

        //function for updating reputation
        Users[u].totalbytes += _totalbytes;


    }

    function updateUseravgDelay(address u, int _avgDelay) public{

        //function for updating reputation
        int x= Users[u].avgdelay + _avgDelay;
        Users[u].avgdelay = x/2;

    }

    

    function userReputation(address u) public view returns (int){

        if(Users[u].reputation >= 0)
            return Users[u].reputation;
        else return -1;

    }

}

