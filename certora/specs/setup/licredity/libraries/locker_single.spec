// CVL implementation of Locker library potentially reducing run-time

methods {
    function Locker.unlock() internal 
        => unlockCVL();

    function Locker.lock() internal 
        => lockCVL();
    
    function Locker.register(bytes32 item) internal 
        => registerCVL();
    
    function Locker.registeredItems() internal returns (bytes32[] memory) 
        => registeredItemsCVL();
}

persistent ghost bool ghostLockerRegisteredItems;

function unlockCVL() { }

function lockCVL() { }

function registerCVL() {
    ghostLockerRegisteredItems = true;
}

function registeredItemsCVL() returns bytes32[] {
    bytes32[] items;    
    return items;
}