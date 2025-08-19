# Retreat Centers and Wellness Facilities Smart Contract System

A comprehensive Clarity smart contract system for managing retreat centers and wellness facilities on the Stacks blockchain.

## Overview

This system provides a decentralized platform for retreat centers to manage their operations transparently and securely. It handles program scheduling, instructor certification, participant health tracking, pricing coordination, and outcome measurement.

## Core Features

### 1. Program Scheduling & Management
- Create and manage retreat programs with detailed information
- Set capacity limits and track enrollment
- Handle program status updates (active, cancelled, completed)
- Manage program dates and duration

### 2. Instructor Certification Verification
- Register certified instructors with verification status
- Track instructor specializations and qualifications
- Manage instructor assignments to programs
- Maintain certification expiry tracking

### 3. Participant Health & Safety
- Secure storage of participant health requirements
- Track safety compliance and medical clearances
- Manage emergency contact information
- Handle dietary restrictions and accessibility needs

### 4. Transparent Pricing & Accommodation
- Set and manage program pricing structures
- Handle accommodation booking and coordination
- Track payment status and refund policies
- Manage capacity-based pricing tiers

### 5. Outcome Tracking & Effectiveness
- Record participant feedback and ratings
- Track program completion rates
- Measure wellness outcome metrics
- Generate effectiveness reports

## Contract Architecture

The system consists of five independent smart contracts:

1. **retreat-management.clar** - Core retreat program management
2. **instructor-certification.clar** - Instructor verification and management
3. **participant-health.clar** - Health and safety tracking
4. **pricing-accommodation.clar** - Pricing and accommodation coordination
5. **outcome-tracking.clar** - Program effectiveness and outcome measurement

## Key Design Principles

- **Privacy-First**: Sensitive health information is hashed and stored securely
- **Transparency**: Pricing, instructor credentials, and program details are publicly verifiable
- **Decentralized**: No single point of failure or control
- **Scalable**: Designed to handle multiple retreat centers and thousands of participants
- **Compliance-Ready**: Built with health and safety regulations in mind

## Data Types

### Program Information
- Program ID, name, description, and category
- Start/end dates, capacity, and current enrollment
- Pricing structure and accommodation details
- Instructor assignments and requirements

### Participant Data
- Participant ID and basic information
- Health requirements (hashed for privacy)
- Emergency contacts and dietary needs
- Program enrollment and completion status

### Instructor Credentials
- Instructor ID and certification details
- Specializations and qualification levels
- Certification expiry and renewal status
- Program assignment history

## Security Features

- Role-based access control for retreat center operators
- Encrypted storage of sensitive participant information
- Immutable audit trail for all operations
- Multi-signature requirements for critical operations

## Getting Started

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `clarinet test` to execute test suite
5. Deploy contracts using `clarinet deploy`

## Testing

The system includes comprehensive tests using Vitest covering:
- Contract deployment and initialization
- Program creation and management
- Instructor certification workflows
- Participant enrollment and health tracking
- Pricing and accommodation booking
- Outcome recording and reporting

## License

MIT License - see LICENSE file for details.
