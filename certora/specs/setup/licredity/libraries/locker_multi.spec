// CVL implementation of Locker library potentially reducing run-time

methods {
    function Locker.unlock() internal 
        => unlockCVL();

    function Locker.lock() internal 
        => lockCVL();
    
    function Locker.register(bytes32 item) internal 
        => registerCVL(item);
    
    function Locker.registeredItems() internal returns (bytes32[] memory) 
        => registeredItemsCVL();
}

persistent ghost mapping(bytes32 => bool) ghostLockerRegisteredItems;

function unlockCVL() {
    require(forall bytes32 item. ghostLockerRegisteredItems[item] == false, "Clear all Locker items");
}

function lockCVL() { }

function registerCVL(bytes32 item) {
    ghostLockerRegisteredItems[item] = true;
}

function registeredItemsCVL() returns bytes32[] {
    bytes32[] items;    
    return items;
}