pragma solidity 0.8.7;

contract div {
    function divtwo(uint a, uint b) public pure returns(uint) {
        if(a>b) {
            return a-b;
        } else {
            return b-a;
        }
    }
}