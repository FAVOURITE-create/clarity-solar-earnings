import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test adding participants",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const participant1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('solar-earnings', 'add-participant', [
                types.principal(participant1.address),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    },
});

Clarinet.test({
    name: "Test recording earnings",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('solar-earnings', 'record-earnings', [
                types.uint(1000)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let totalEarnings = chain.mineBlock([
            Tx.contractCall('solar-earnings', 'get-total-earnings', [], deployer.address)
        ]);
        
        assertEquals(totalEarnings.receipts[0].result.expectOk(), types.uint(1000));
    },
});

Clarinet.test({
    name: "Test participant earnings and withdrawal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const participant1 = accounts.get('wallet_1')!;
        
        chain.mineBlock([
            Tx.contractCall('solar-earnings', 'add-participant', [
                types.principal(participant1.address),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('solar-earnings', 'record-earnings', [
                types.uint(1000)
            ], deployer.address)
        ]);
        
        let earnings = chain.mineBlock([
            Tx.contractCall('solar-earnings', 'get-participant-earnings', [
                types.principal(participant1.address)
            ], participant1.address)
        ]);
        
        earnings.receipts[0].result.expectOk();
        
        let withdrawal = chain.mineBlock([
            Tx.contractCall('solar-earnings', 'withdraw-earnings', [], participant1.address)
        ]);
        
        withdrawal.receipts[0].result.expectOk();
    },
});
