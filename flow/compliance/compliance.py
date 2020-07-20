#!/usr/bin/python3

"""
A script for running selfchecking tests in a python harness
"""

import os
import sys
import operator
import subprocess

class ComplianceTest(object):
    """
    Represents a single selfchecking test
    """

    def __init__(self,
                 src_filepath,
                 end_addr,
                 sig_addr_begin,
                 sig_addr_end,
                 reg_addr,
                 src_type,
                 test_class,
                 name=None):
        """
        Create a new compliance test class
        """
        self.src_filepath = src_filepath
        self.sig_filepath = None
        self.end_addr     = end_addr    # Final address of the test
        self.sig_addr_begin= sig_addr_begin    # Compliance signature start
        self.sig_addr_end = sig_addr_end # Compliance signature end
        self.reg_addr     = reg_addr    # register state begin address
        self.src_type     = src_type
        self.name         = name
        self.test_class   = test_class

    def __repr__(self):
        return "%s %s %s" % (
            hex(self.pass_addr), hex(self.fail_addr), self.src_filepath
        )

    def fromSRECAndObjdump(srec_filepath, objdump_filepath,name,testclass):
        """
        Create a new selfchecking test from a path to a srec filepath and
        an objdump filepath, both of which correspond to the same test.
        """
        sa = None
        se = None
        endaddr = None
        fa_offset =-4 

        with open(objdump_filepath,"r") as fh:
        
            for line in fh.readlines():
                tokens = line.split()

                if(len(tokens) == 2 and tokens[1] == "<end_testcode>:"):
                    endaddr = int(tokens[0], base=16) + fa_offset
                elif(len(tokens) == 2 and tokens[1] == "<begin_signature>:"):
                    sa = int(tokens[0], base=16) 
                elif(len(tokens) == 2 and tokens[1] == "<end_signature>:"):
                    se = int(tokens[0], base=16) 
                elif(len(tokens) == 2 and tokens[1] == "<begin_regstate>:"):
                    rs = int(tokens[0], base=16) 
                else:
                    continue
        
        if(endaddr  == None):
            raise Exception(
                "Failed to find fail address in %s" % objdump_filepath
            )
        if(sa == None):
            raise Exception(
                "Failed to find signature address in %s" % objdump_filepath
            )

        return ComplianceTest(
            srec_filepath,
            endaddr, sa,se,rs,"srec",testclass,
            name=name)

def loadTests(srec_root, objdump_root, testclass):
    """
    Load the set of compliance tests, using the supplied arguments
    as directories containing the srec and objdump files
    """

    tname_list = [f.split(".")[0] for f in os.listdir(srec_root) if 
        os.path.isfile(os.path.join(srec_root,f))]

    tname_list = list(set(tname_list))

    srec_list    = [os.path.join(srec_root,f) for f in tname_list]
    objdump_list = [os.path.join(objdump_root,f) for f in tname_list]
    
    srec_list       = [f+".elf.srec" for f in srec_list]
    objdump_list    = [f+".elf.objdump" for f in objdump_list]
    signature_list  = [f.replace(".elf.objdump",".signature.output") for f in objdump_list]

    tests       = []
    file_tuples = zip(srec_list, objdump_list, tname_list, signature_list)

    for (s, o, n,sl) in file_tuples:
        try:
            newtest = ComplianceTest.fromSRECAndObjdump(s,o,n,testclass)
            newtest.sig_filepath = sl
            tests.append(newtest)

        except Exception as e:
            print("ERROR: %s" % str(e))
            pass

    return tests

def main():
    tests   = []
    
    tests   += loadTests("work/riscv-compliance/rv32i",
                         "external/riscv-compliance/work/rv32i",
                         "rv32i")
    tests   += loadTests("work/riscv-compliance/rv32im",
                         "external/riscv-compliance/work/rv32im",
                         "rv32im")
    tests   += loadTests("work/riscv-compliance/rv32imc",
                         "external/riscv-compliance/work/rv32imc",
                         "rv32imc")

    tests.sort(key=operator.attrgetter('name'))

    # Tests we expect to fail, and when the divergence should occur.
    expect_test_fails = [
        "I-MISALIGN_JMP-01",
        "I-MISALIGN_LDST-01"
    ]

    sim     = "work/verilator/frv_core/verilated-frv_core"
    wavesdir= "work/riscv-compliance"
    timeout = 5000
    exitcode= 0

    passes,expected_fails,fails,timeouts, unknowns = 0,0,0,0,0

    print("%11s %20s %s" % (
        "Result", "Test", "Sim command"
    ))
    print("-"*80)

    for t in tests:
        
        args = [
            sim,
            "+IMEM=%s" % t.src_filepath,
            "+PASS_ADDR=%s" % hex(t.end_addr),
            "+WAVES=%s" % os.path.join(wavesdir,t.test_class,t.name+".vcd"),
            "+TIMEOUT=%d" % timeout,
            "+SIG_START=%s" % hex(t.sig_addr_begin),
            "+SIG_END=%s" % hex(t.sig_addr_end),
            "+REG_ADDR=%s" % hex(t.reg_addr),
            "+SIG_PATH=%s" % os.path.join(wavesdir,t.test_class,t.name+".sig")
        ]

        if(t.sig_filepath):
            args.append("+SIG_VERIF=%s"%t.sig_filepath)
        
        result = subprocess.run(
            args, 
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )
        
        msg = "Unknown"

        if(">> SIM PASS" in result.stdout):
            
            msg = "PASS"
            passes += 1
        
        elif(">> SIG FAIL" in result.stdout):
                
            msg = "SIG FAIL"
            if(t.name in expect_test_fails):
                msg = "EXP SIG FAIL"
                expected_fails += 1
            fails += 1

        elif(">> SIM FAIL" in result.stdout):
            
            if(t.name in expect_test_fails):
                msg = "EXP FAIL"
                expected_fails += 1
            else:
                msg = "FAIL"
                exitcode += 1
                fails += 1

        elif(">> TIMEOUT" in result.stdout):

            if(t.name in expect_test_fails):
                msg = "EXP TIMEOUT"
                timeouts += 1
                expected_fails += 1
            else:
                msg = "TIMEOUT"
                exitcode += 1
                timeouts += 1
        
        logpath = os.path.join(wavesdir,t.test_class,t.name+".log")
        with open(logpath,"w") as fh:
            fh.write(result.stdout)

        print("%11s %20s %s" % (
            str(msg), t.name, " "#" ".join(args)
        ))

    print("p=%d / f=%d / t=%d / u=%d / ef=%d" % (
        passes, fails, timeouts, len(tests)-passes-fails-timeouts,
        expected_fails
    ))
    return fails + timeouts - expected_fails

if(__name__ == "__main__"):
    ec = main()
    if(ec == 0):
        print("--- Success ---")
    else:
        print("--- Failure ---")
    sys.exit(ec)

