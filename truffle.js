module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
    networks: {
        development: {
            host: "127.0.0.1",
            port: 9545,
            network_id: "*" // Match any network id
        }
    },
    solc: {

      // remappings: ['zos-lib/contracts/migrations/Migratable.sol:asdf', '']

        //,'zos-lib/:./submodules/zos-lib/']

      // optimizer: {
      //   enabled: true,
      //   runs: 200
      // }
    }
};