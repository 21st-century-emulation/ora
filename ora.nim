import bitops
import httpclient
import jester
import json
import os
import strutils

type
  CpuFlags = object
    sign: bool
    zero: bool
    auxCarry: bool
    parity: bool
    carry: bool

type
  CpuState = object
    a: uint8
    b: uint8
    c: uint8
    d: uint8
    e: uint8
    h: uint8
    l: uint8
    stackPointer: uint16
    programCounter: uint16
    cycles: uint64
    interruptsEnabled: bool
    flags: CpuFlags

type
  Cpu = object
    opcode: uint8
    id: string
    state: CpuState

settings:
  port = Port(8080)
  bindAddr = "0.0.0.0"

routes:
  get "/status":
    resp "Healthy", "text/plain"

  get "/api/v1/debug/readByte":
    resp "10", "text/plain"

  post "/api/v1/execute":
    var cpu = to(parseJson($request.body), Cpu)

    let operand = case cpu.opcode:
      of 0xB0:
        cpu.state.b
      of 0xB1:
        cpu.state.c
      of 0xB2:
        cpu.state.d
      of 0xB3:
        cpu.state.e
      of 0xB4:
        cpu.state.h
      of 0xB5:
        cpu.state.l
      of 0xB6:
        let READ_MEMORY_API = getEnv("READ_MEMORY_API")
        let address = (cpu.state.h shl 8) or cpu.state.l;
        let client = newAsyncHttpClient();
        cpu.state.cycles += 3;
        uint8(parseUInt(waitFor client.getContent(READ_MEMORY_API & "?address=" & $address & "&id=" & cpu.id)))
      of 0xB7:
        cpu.state.a
      else:
        raise newException(Exception, "Invalid opcode " & $cpu.opcode)

    cpu.state.a = cpu.state.a or operand
    cpu.state.flags.sign = cpu.state.a.testBit(7);
    cpu.state.flags.zero = cpu.state.a == 0;
    cpu.state.flags.aux_carry = false;
    cpu.state.flags.parity = parityBits(cpu.state.a) == 0;
    cpu.state.flags.carry = false;
    cpu.state.cycles += 4;
    resp $(%* cpu)
