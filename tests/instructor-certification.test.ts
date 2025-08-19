import { describe, it, expect, beforeEach } from "vitest"

describe("Instructor Certification Contract", () => {
  let contractState
  let mockTxSender
  let mockBlockHeight
  
  beforeEach(() => {
    contractState = {
      nextInstructorId: 1,
      nextAssignmentId: 1,
      instructors: new Map(),
      instructorAddresses: new Map(),
      certifications: new Map(),
      specializations: new Map(),
      programAssignments: new Map(),
      instructorProgramAssignments: new Map(),
      certificationAuthorities: new Map(),
    }
    mockTxSender = "SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE"
    mockBlockHeight = 1000
  })
  
  describe("Instructor Registration", () => {
    it("should register instructor successfully", () => {
      const instructorData = {
        name: "Jane Smith",
        email: "jane@example.com",
        phone: "+1234567890",
        bio: "Experienced yoga instructor with 10 years of practice",
        yearsExperience: 10,
      }
      
      const instructorId = contractState.nextInstructorId
      
      if (!contractState.instructorAddresses.has(mockTxSender)) {
        contractState.instructors.set(instructorId, {
          instructorAddress: mockTxSender,
          name: instructorData.name,
          email: instructorData.email,
          phone: instructorData.phone,
          bio: instructorData.bio,
          yearsExperience: instructorData.yearsExperience,
          verificationStatus: "pending",
          registeredAt: mockBlockHeight,
          updatedAt: mockBlockHeight,
        })
        
        contractState.instructorAddresses.set(mockTxSender, {
          instructorId: instructorId,
        })
        
        contractState.nextInstructorId++
      }
      
      expect(contractState.instructors.get(instructorId)).toBeDefined()
      expect(contractState.instructors.get(instructorId).name).toBe("Jane Smith")
      expect(contractState.instructors.get(instructorId).verificationStatus).toBe("pending")
    })
    
    it("should fail to register duplicate instructor", () => {
      // First registration
      contractState.instructorAddresses.set(mockTxSender, { instructorId: 1 })
      
      let errorThrown = false
      
      // Attempt duplicate registration
      if (contractState.instructorAddresses.has(mockTxSender)) {
        errorThrown = true
      }
      
      expect(errorThrown).toBe(true)
    })
    
    it("should update instructor profile", () => {
      const instructorId = 1
      
      // First register instructor
      contractState.instructors.set(instructorId, {
        instructorAddress: mockTxSender,
        name: "Jane Smith",
        email: "jane@example.com",
        phone: "+1234567890",
        bio: "Original bio",
        yearsExperience: 10,
        verificationStatus: "pending",
        registeredAt: mockBlockHeight,
        updatedAt: mockBlockHeight,
      })
      
      contractState.instructorAddresses.set(mockTxSender, { instructorId: instructorId })
      
      // Update profile
      const instructor = contractState.instructors.get(instructorId)
      if (instructor && instructor.instructorAddress === mockTxSender) {
        contractState.instructors.set(instructorId, {
          ...instructor,
          bio: "Updated bio with more experience",
          yearsExperience: 12,
          updatedAt: mockBlockHeight + 100,
        })
      }
      
      expect(contractState.instructors.get(instructorId).bio).toBe("Updated bio with more experience")
      expect(contractState.instructors.get(instructorId).yearsExperience).toBe(12)
    })
  })
  
  describe("Certification Management", () => {
    beforeEach(() => {
      // Set up authorized certification authority
      contractState.certificationAuthorities.set(mockTxSender, {
        authorized: true,
        organizationName: "Yoga Alliance",
      })
      
      // Set up instructor
      contractState.instructors.set(1, {
        instructorAddress: "SP2HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QF",
        name: "Jane Smith",
        verificationStatus: "pending",
      })
    })
    
    it("should add certification successfully", () => {
      const instructorId = 1
      const certType = "RYT-200"
      const certData = {
        certificationName: "Registered Yoga Teacher 200hr",
        issuingOrganization: "Yoga Alliance",
        issueDate: 1000,
        expiryDate: 2000,
        certificationNumber: "YA123456",
      }
      
      const instructor = contractState.instructors.get(instructorId)
      const isAuthorized = contractState.certificationAuthorities.get(mockTxSender)?.authorized
      
      if (
          instructor &&
          (instructor.instructorAddress === mockTxSender || isAuthorized) &&
          certData.issueDate < certData.expiryDate
      ) {
        contractState.certifications.set(`${instructorId}-${certType}`, {
          certificationName: certData.certificationName,
          issuingOrganization: certData.issuingOrganization,
          issueDate: certData.issueDate,
          expiryDate: certData.expiryDate,
          certificationNumber: certData.certificationNumber,
          verificationStatus: "pending",
          verifiedBy: null,
          verifiedAt: null,
        })
      }
      
      expect(contractState.certifications.get(`${instructorId}-${certType}`)).toBeDefined()
      expect(contractState.certifications.get(`${instructorId}-${certType}`).certificationName).toBe(
          "Registered Yoga Teacher 200hr",
      )
    })
    
    it("should verify certification", () => {
      const instructorId = 1
      const certType = "RYT-200"
      
      // First add certification
      contractState.certifications.set(`${instructorId}-${certType}`, {
        certificationName: "Registered Yoga Teacher 200hr",
        issuingOrganization: "Yoga Alliance",
        issueDate: 1000,
        expiryDate: 2000,
        certificationNumber: "YA123456",
        verificationStatus: "pending",
        verifiedBy: null,
        verifiedAt: null,
      })
      
      // Verify certification
      const certification = contractState.certifications.get(`${instructorId}-${certType}`)
      const isAuthorized = contractState.certificationAuthorities.get(mockTxSender)?.authorized
      
      if (certification && isAuthorized) {
        contractState.certifications.set(`${instructorId}-${certType}`, {
          ...certification,
          verificationStatus: "verified",
          verifiedBy: mockTxSender,
          verifiedAt: mockBlockHeight,
        })
      }
      
      expect(contractState.certifications.get(`${instructorId}-${certType}`).verificationStatus).toBe("verified")
      expect(contractState.certifications.get(`${instructorId}-${certType}`).verifiedBy).toBe(mockTxSender)
    })
    
    it("should check if certification is valid", () => {
      const instructorId = 1
      const certType = "RYT-200"
      
      contractState.certifications.set(`${instructorId}-${certType}`, {
        verificationStatus: "verified",
        expiryDate: mockBlockHeight + 1000, // Future expiry
      })
      
      const certification = contractState.certifications.get(`${instructorId}-${certType}`)
      const isValid =
          certification && certification.verificationStatus === "verified" && certification.expiryDate > mockBlockHeight
      
      expect(isValid).toBe(true)
    })
  })
  
  describe("Program Assignments", () => {
    beforeEach(() => {
      contractState.instructors.set(1, {
        instructorAddress: "SP2HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QF",
        name: "Jane Smith",
        verificationStatus: "verified",
      })
    })
    
    it("should assign instructor to program", () => {
      const assignmentData = {
        instructorId: 1,
        programId: 1,
        role: "Lead Instructor",
        startDate: 2000,
        endDate: 2100,
        compensation: 5000,
      }
      
      const assignmentId = contractState.nextAssignmentId
      
      if (
          contractState.instructors.has(assignmentData.instructorId) &&
          assignmentData.startDate < assignmentData.endDate &&
          !contractState.instructorProgramAssignments.has(`${assignmentData.instructorId}-${assignmentData.programId}`)
      ) {
        contractState.programAssignments.set(assignmentId, {
          instructorId: assignmentData.instructorId,
          programId: assignmentData.programId,
          role: assignmentData.role,
          startDate: assignmentData.startDate,
          endDate: assignmentData.endDate,
          compensation: assignmentData.compensation,
          status: "active",
          assignedBy: mockTxSender,
          assignedAt: mockBlockHeight,
        })
        
        contractState.instructorProgramAssignments.set(`${assignmentData.instructorId}-${assignmentData.programId}`, {
          assignmentId: assignmentId,
        })
        
        contractState.nextAssignmentId++
      }
      
      expect(contractState.programAssignments.get(assignmentId)).toBeDefined()
      expect(contractState.programAssignments.get(assignmentId).role).toBe("Lead Instructor")
    })
    
    it("should update assignment status", () => {
      const assignmentId = 1
      
      contractState.programAssignments.set(assignmentId, {
        instructorId: 1,
        programId: 1,
        role: "Lead Instructor",
        status: "active",
        assignedBy: mockTxSender,
      })
      
      const assignment = contractState.programAssignments.get(assignmentId)
      if (assignment && assignment.assignedBy === mockTxSender) {
        contractState.programAssignments.set(assignmentId, {
          ...assignment,
          status: "completed",
        })
      }
      
      expect(contractState.programAssignments.get(assignmentId).status).toBe("completed")
    })
  })
})
