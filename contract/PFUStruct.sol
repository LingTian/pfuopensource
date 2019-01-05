pragma solidity ^0.4.24;

contract PFUStruct {

struct PFU{
string name;
uint level;
uint power;
uint32 creatTime;
uint32 rarity;
}

// auction
struct Bidder{
address [] addrs;
uint [] moneys;
uint money;
uint32 startTime;
bool grant;
}
}
