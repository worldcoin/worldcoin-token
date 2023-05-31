# By default we want to build.
all: install build

# ===== Basic Development Rules =======================================================================================

# Install forge dependencies (not needed if submodules are already initialized).
install:; forge install && yarn install

# Build contracts and inject the Poseidon library.
build:; forge build

# Run tests, with debug information and gas reports.
test:; FOUNDRY_PROFILE=debug forge test

# Create mock data and create configuration files for deployment script.
mock-config:; ts-node script/generate-mock-config.ts

# ===== Profiling Rules ===============================================================================================

# Benchmark the tests.
bench:; FOUNDRY_PROFILE=bench forge test --gas-report 

# Snapshot the current test usages.
snapshot:; FOUNDRY_PROFILE=bench forge snapshot 


# ===== Deployment Rules =================================================================================================

# Deployment command is in README.md

# ===== Utility Rules =================================================================================================

# Format the solidity code.
format:; forge fmt; npx prettier --write .

# Lint the solidity code.
lint:; yarn lint

# Clean the build artifacts.
clean:; forge clean

# Get a test coverage report.
coverage:; forge coverage

# Update forge dependencies.
update:; forge update

# ===== Documentation Rules ============================================================================================

# Generate the documentation.
doc:; forge doc --build; forge doc --serve -p 3000
