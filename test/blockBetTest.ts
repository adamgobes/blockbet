import { ethers } from 'hardhat'
import { Contract } from '@ethersproject/contracts'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber } from '@ethersproject/bignumber'
import { expect } from 'chai'
import { Sign } from 'crypto'

let addresses: SignerWithAddress[]

let erc20Token: any
let blockBet: any
let sportsFeedOracle: any

const BET_AMOUNT = 100

describe('BlockBet', function () {
    beforeEach(async function () {
        addresses = await ethers.getSigners()

        await deployERC20()
        await deploySportsFeedOracle()

        await erc20Token.connect(addresses[1]).mintDummy()
        await erc20Token.connect(addresses[2]).mintDummy()

        const BlockBetContract = await ethers.getContractFactory('BlockBet')

        blockBet = await BlockBetContract.deploy(sportsFeedOracle.address)

        await blockBet.deployed()
    })

    it('should allow a user to create a bet', async function () {
        const initiatingAddress = addresses[1]
        const receivingAddress = addresses[2]

        const balanceBefore: BigNumber = await erc20Token.balanceOf(
            initiatingAddress.address
        )

        await createBet(initiatingAddress, receivingAddress, 1, 2, 123)

        expect(await erc20Token.balanceOf(initiatingAddress.address)).to.equal(
            balanceBefore.sub(BET_AMOUNT)
        )

        expect(
            (await blockBet.getBetsForAddress(initiatingAddress.address)).length
        ).to.equal(1)
    })

    it('should allow a user to accept a bet', async function () {
        const initiatingAddress = addresses[1]
        const receivingAddress = addresses[2]

        const balanceBefore: BigNumber = await erc20Token.balanceOf(
            initiatingAddress.address
        )

        let bet = await createBet(
            initiatingAddress,
            receivingAddress,
            1,
            2,
            123
        )

        expect(bet.betAccepted).to.be.false

        await erc20Token
            .connect(receivingAddress)
            .approve(blockBet.address, BET_AMOUNT)

        await blockBet.connect(receivingAddress).acceptBet(bet.betId)

        bet = await blockBet.getBetById(bet.betId)
        expect(bet.betAccepted).to.be.true

        expect(await erc20Token.balanceOf(receivingAddress.address)).to.equal(
            balanceBefore.sub(BET_AMOUNT)
        )
    })
})

async function createBet(
    initiatingAddress: SignerWithAddress,
    receivingAddress: SignerWithAddress,
    teamOne: number,
    teamTwo: number,
    gameId: number
) {
    await erc20Token
        .connect(initiatingAddress)
        .approve(blockBet.address, BET_AMOUNT)

    await blockBet
        .connect(initiatingAddress)
        .placeBet(
            receivingAddress.address,
            teamOne,
            teamTwo,
            BET_AMOUNT,
            erc20Token.address,
            gameId
        )

    const allBets = await blockBet.getBetsForAddress(initiatingAddress.address)
    const bet = allBets[allBets.length - 1]

    return bet
}

async function deploySportsFeedOracle() {
    const OracleContract = await ethers.getContractFactory('MockSportsFeed')
    sportsFeedOracle = await OracleContract.deploy()
    await sportsFeedOracle.deployed()
}

async function deployERC20() {
    const TokenContract = await ethers.getContractFactory('ERC20Token')
    erc20Token = await TokenContract.deploy()
    await erc20Token.deployed()
}
