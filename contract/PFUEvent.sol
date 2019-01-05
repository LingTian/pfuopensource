pragma solidity ^0.4.24;

contract PFUEvent {

// creatpfusEvent
event creatPFUsEvent(string name,  uint32 time, uint32 rarity, uint vamId, uint dna, uint level, uint fatherID);

// renamepfuEvent
event renamePFUEvent(uint vamId, string name);

// Battle victory
event battleVictory(uint vamId);

// Maximum amount of auction
event auction(address addr, uint amount, uint vamId);
}
