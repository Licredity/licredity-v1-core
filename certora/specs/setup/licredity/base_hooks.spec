// CVL specification for BaseHooks abstract contract methods marked as NONDET/DELETE for verification

using LicredityHarness as _LicredityBaseHooks;

methods {
    function _LicredityBaseHooks.beforeInitialize(address, LicredityHarness.PoolKey, uint160) external returns (bytes4)
        => NONDET DELETE;
    
    function _LicredityBaseHooks.afterInitialize(address, LicredityHarness.PoolKey, uint160, int24) external returns (bytes4)
        => NONDET DELETE;
    
    function _LicredityBaseHooks.beforeAddLiquidity(address, LicredityHarness.PoolKey, IPoolManager.ModifyLiquidityParams, bytes) external returns (bytes4)
        => NONDET DELETE;

    function _LicredityBaseHooks.beforeRemoveLiquidity(address, LicredityHarness.PoolKey, IPoolManager.ModifyLiquidityParams, bytes) external returns (bytes4)
        => NONDET DELETE;

    function _LicredityBaseHooks.afterAddLiquidity(address, LicredityHarness.PoolKey, IPoolManager.ModifyLiquidityParams, LicredityHarness.BalanceDelta, LicredityHarness.BalanceDelta, bytes) external returns (bytes4, LicredityHarness.BalanceDelta)
        => NONDET DELETE;

    function _LicredityBaseHooks.afterRemoveLiquidity(address, LicredityHarness.PoolKey, IPoolManager.ModifyLiquidityParams, LicredityHarness.BalanceDelta, LicredityHarness.BalanceDelta, bytes) external returns (bytes4, LicredityHarness.BalanceDelta)
        => NONDET DELETE;

    function _LicredityBaseHooks.beforeSwap(address, LicredityHarness.PoolKey, IPoolManager.SwapParams, bytes) external returns (bytes4, LicredityHarness.BeforeSwapDelta, uint24)
        => NONDET DELETE;

    function _LicredityBaseHooks.afterSwap(address, LicredityHarness.PoolKey, IPoolManager.SwapParams, LicredityHarness.BalanceDelta, bytes) external returns (bytes4, int128)
        => NONDET DELETE;

    function _LicredityBaseHooks.beforeDonate(address, LicredityHarness.PoolKey, uint256, uint256, bytes) external returns (bytes4)
        => NONDET DELETE;

    function _LicredityBaseHooks.afterDonate(address, LicredityHarness.PoolKey, uint256, uint256, bytes) external returns (bytes4)
        => NONDET DELETE;    
}