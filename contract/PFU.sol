pragma solidity ^0.4.24;

import "./ownable.sol";
import "./SafeMath.sol";
import "./PFUEvent.sol";
import "./PFUStruct.sol";

contract TRC721 {
function balanceOf(address _owner) public constant returns (uint balance);
//所有权相关的接口
function ownerOf(uint256 _tokenId) public constant returns (address owner);
function approve(address _to, uint256 _tokenId) public;
function takeOwnership(uint256 _tokenId) public;
function transfer(address _to, uint256 _tokenId) public;
//事件
event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract TRC20{
uint256 public totalSupply;

function balanceOf(address _owner) public constant returns (uint256 balance);
function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns
(bool success);

function approve(address _spender, uint256 _value) public returns (bool success);

function allowance(address _owner, address _spender) public constant returns
(uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256
_value);
}

contract PFU is Ownable, PFUEvent, PFUStruct, TRC721 {

using SafeMath for *;

uint dnaDigits = 20;
uint dnaModulus = 10 ** dnaDigits; // dna bits
uint creatcooling; // How long does it take to create one
uint dayCountMoney; // Price of single breeding
uint randNonce = 0; // Random number nonce calculation valuep
uint singMoney; // Number of login gifts
uint renameMoney; // Renaming fee
uint creatNewpfuMoney; // Fee for creating new PFUs
uint battleMoney;// Combat fees
uint battleWinMoney;// Battle winning bonus
uint startBidderMoney; // Commissions for auction
uint bidderMoney; // Auction fee
uint biddersTime; // Bidding time
uint32 createNewTime; // The time of the last PFU feeding.
uint32 winBattle;// The winning ratio of battle
uint32 battleColling; // Combat cooling time
uint32 lastTimeBattle; // Last combat time
address contractAddress; // Current contract address collection contract address

TRC20 trc20; // Token contracts

PFUStruct.PFU [] public PFUs; //PFU []
PFUStruct.Bidder [] public bidder; //bidder []

mapping (uint => address) pfuToAddr; //uint => address PFU number corresponding user
mapping (address => uint) addrpfuCount; //address => count Number of PFUs for users
mapping (address => uint) addrToSignCount; //address => count User sign in days
mapping (uint => uint) pfuToAuction; // PFUid => batter PFU corresponding auction structure id
mapping (uint => address) pfuApprovals; // erc721 => approval To grant authorization

//PFUOwner
modifier PFUOwner(uint _PFUid){
require(msg.sender == pfuToAddr[_PFUid]);
_;
}

function ()
public
payable
{}

// Set erc20 token address
function setErc20Address(address _erc20)
public
onlyOwner
{
erc20 = ERC20(_erc20);
}

// How long can it generate the cost of PFUs again
function setCreatCooling(uint _time, uint _dayCountMoney)
public
onlyOwner
{
creatcooling = 1 seconds * _time;
dayCountMoney = _dayCountMoney;

}

// How long can it generate the cost of PFUs again
function setWinBattle(uint32 _winBattle)
public
onlyOwner
{
winBattle = _winBattle;
}

// Set the combat cooldown time.
function setbattleColling(uint32 _battleColling)
public
onlyOwner
{
battleColling = _battleColling;

}
// set Bidding time
function setBiddingTime(uint _biddersTime)
public
onlyOwner
{
biddersTime = 1 seconds * _biddersTime;
}

// Set up Commission
function setFee(uint _singMoney,
uint _renameMoney,
uint _creatNewpfuMoney,
uint _battleMoney,
uint _battleWinMoney,
uint _startBidderMoney,
uint _bidderMoney)
public
onlyOwner
{
singMoney = _singMoney.mul(1000000000000000000); // Number of login gifts
renameMoney = _renameMoney.mul(1000000000000000000); // Renaming fee
creatNewpfuMoney = _creatNewpfuMoney.mul(1000000000000000000); // Fee for creating new PFUs
battleMoney = _battleMoney.mul(1000000000000000000);// Combat fees
battleWinMoney = _battleWinMoney.mul(1000000000000000000); // Battle winning bonus
startBidderMoney = _startBidderMoney.mul(1000000000000000000); // Commissions for auction
bidderMoney = _bidderMoney.mul(1000000000000000000); // Auction fee
}

// Creating new PFUs
function creatShips()
public
{
// Each user is generated once.
require(addrpfuCount[msg.sender] == 0);
uint32 time = uint32(now);
uint32 rarity = _getRarity();
_creatPFUs(time, rarity, 1, 0);

}

// PFUs eat food ,Creating new PFUs
function creatNewPFUs(uint _PFUid)
public
PFUOwner(_PFUid)
{
// Over cooling time
require(now > createNewTime + creatcooling);

// Use erc20 token as a handling fee.
require(erc20.balanceOf(msg.sender) >= creatNewpfuMoney);
erc20.transferFrom(msg.sender, contractAddress, creatNewpfuMoney);

// Reset the time to create new creatures.
createNewTime = uint32(now);
if(_getRarity() == 1 && _PFUid != 0)
uint32 rarity = _getRarity();
_creatPFUs(createNewTime, rarity, PFUs[_PFUid].level, _PFUid);

}

// Create high varity PFUs
function createVarityPFUs(uint32 rarity)
public
onlyOwner
{
uint32 time = uint32(now);
_creatPFUs(time, rarity, 1, 0);

}

// _creatPFUs private
function _creatPFUs(uint32 time,
uint32 rarity,
uint level,
uint
fatherID)
private
{
// PFUs.push
uint id = PFUs.push(PFUStruct.PFU("%E5%90%B8%E8%A1%80%E9%AC%BC", level, 100, time, rarity)).sub(1);
// set pfuToAddr
pfuToAddr[id] = msg.sender;
// addrpfuCount++
addrpfuCount[msg.sender] = addrpfuCount[msg.sender].add(1);
// Creat  event
emit creatPFUsEvent("%E5%90%B8%E8%A1%80%E9%AC%BC", time, rarity, id, level);

}

// Calculated rarity
function _getRarity()
private
view
returns(uint32)
{
// Generating random numbers
uint random = _getRandom();
// Get 1-5 different rarity according to scale.
if(random <= 5)
return 5;
else if(random <= 15 && random > 5)
return 4;
else if(random <= 30 && random >15)
return 3;
else if(random <= 50 && random > 30)
return 2;
else
return 1;

}

// Get random numbers
function _getRandom()
private
returns (uint)
{
uint random = uint(keccak256(now, msg.sender, randNonce)) % 100;
randNonce++;
return random;
}


// rename PFU
function renamePFU(string _name, uint _PFUid)
public
PFUOwner(_PFUid)
{
// Use erc20 token as a handling fee.
require(erc20.balanceOf(msg.sender) >= renameMoney);
erc20.transferFrom(msg.sender, contractAddress, renameMoney);

PFUs[_PFUid].name = _name;
emit renamePFUEvent(_PFUid, _name);

}

// PFU fighting  ， Get some profits
function Battle(uint _PFUid,
uint _otherPFUid)
public
PFUOwner(_PFUid)
{
require(now > battleColling + lastTimeBattle);
// Use erc20 token as a handling fee.
require(erc20.balanceOf(msg.sender) >= battleMoney);
erc20.transferFrom(msg.sender, contractAddress, battleMoney);

lastTimeBattle = uint32(now);
// Generating random numbers
uint random = _getRandom();
// Winning ratio
if(random > winBattle){
// Calculating combat effectiveness
PFUs[_PFUid].power.add(50);
erc20.transfer(msg.sender, battleWinMoney);
if(PFUs[_otherPFUid].power <= 50)
PFUs[_otherPFUid].power = 0;
else
PFUs[_otherPFUid].power.sub(50);
emit battleVictory(_PFUid);
} else{
// Calculating combat effectiveness
PFUs[_otherPFUid].power.add(50);
if(PFUs[_PFUid].power <= 50)
PFUs[_PFUid].power = 0;
else
PFUs[_PFUid].power.sub(50);
emit battleVictory(_otherPFUid);
}

}

// Users sign in to give token
function sign()
public
{
require(addrToSignCount[msg.sender] <= 14);
addrToSignCount[msg.sender] = addrToSignCount[msg.sender].add(1);
erc20.transfer(msg.sender, singMoney);
}

// Get users of PFUs
function getPFUsByOwner(address _owner)
public
view
returns(uint[])
{
uint[] memory result = new uint[](addrpfuCount[_owner]);
uint counter = 0;
for (uint i = 0; i < PFUs.length; i++) {
if (pfuToAddr[i] == _owner) {
result[counter] = i;
counter++;
}
}
return result;

}

// Start PFU auction
function startBidders(uint money,
uint _PFUid)
public
PFUOwner(_PFUid)
{
// Use erc20 token as a handling fee.
require(erc20.balanceOf(msg.sender) >= startBidderMoney);
erc20.transferFrom(msg.sender, contractAddress, startBidderMoney);

address [] addrs;
uint [] moneys;
uint id = bidder.push(PFUStruct.Bidder(addrs, moneys, money, uint32(now), false)).sub(1);
pfuToAuction[id] = _PFUid;
}

// Start PFU auction
function Bidders(uint money,
uint _PFUid)
public
{
require(now < biddersTime + bidder[pfuToAuction[_PFUid]].startTime);
require(money > bidder[pfuToAuction[_PFUid]].money);
require(money > bidder[pfuToAuction[_PFUid]].moneys[bidder[pfuToAuction[_PFUid]].moneys.length.sub(1)]);
// Use erc20 token as a handling fee.
require(erc20.balanceOf(msg.sender) >= money.mul(1000000000000000000).add(bidderMoney));
erc20.transferFrom(msg.sender, contractAddress, money.mul(1000000000000000000).add(bidderMoney));
// Refund of user auction fee
erc20.transfer(bidder[pfuToAuction[_PFUid]].addrs[0],
bidder[pfuToAuction[_PFUid]].moneys[0].mul(1000000000000000000).add(bidderMoney));

bidder[pfuToAuction[_PFUid]].addrs[0] = msg.sender;
bidder[pfuToAuction[_PFUid]].moneys[0] = money;
emit auction(msg.sender, money, _PFUid);
}

// end PFU auction
function endBidders(uint _PFUid)
public
onlyOwner{
for (uint i = 0; i < bidder.length; i++) {
if (now > biddersTime + bidder[pfuToAuction[_PFUid]].startTime
&& bidder[pfuToAuction[_PFUid]].grant == false) {
erc20.transfer(pfuToAddr[_PFUid], bidder[pfuToAuction[_PFUid]].moneys[0]);
pfuToAddr[_PFUid] = bidder[pfuToAuction[_PFUid]].addrs[0];
bidder[pfuToAuction[_PFUid]].grant = true;
}
}
}

// get PFU count
function balanceOf(address _owner)
public
view
returns
(uint256 _balance)
{
return addrpfuCount[_owner];
}

// Get PFUs users
function ownerOf(uint256 _tokenId)
public
view
returns
(address _owner)
{
return pfuToAddr[_tokenId];
}

//PFU trade
function _transfer(address _from,
address _to,
uint256 _tokenId)
private
{
addrpfuCount[_to] = addrpfuCount[_to].add(1);
addrpfuCount[msg.sender] = addrpfuCount[msg.sender].sub(1);
pfuToAddr[_tokenId] = _to;
emit Transfer(_from, _to, _tokenId);
}

//PFU trade
function transfer(address _to,
uint _PFUid)
public
PFUOwner(_PFUid)
{
_transfer(msg.sender, _to, _PFUid);
}

function approve(address _to,
uint256 _tokenId)
public
PFUOwner(_tokenId)
{
pfuApprovals[_tokenId] = _to;
emit Approval(msg.sender, _to, _tokenId);
}

function takeOwnership(uint256 _tokenId)
public
{
require(pfuApprovals[_tokenId] == msg.sender);
address owner = ownerOf(_tokenId);
_transfer(owner, msg.sender, _tokenId);
}

// withdraw
function withdraw()
public
onlyOwner
{
owner.transfer(address(this).balance);
}

// withdrawalToken
function withdrawalToken()
public
onlyOwner
{
uint256 b = erc20.balanceOf(address(this));
erc20.transfer(owner, b);
}
}
