
import sys

def main():
    ifile = sys.argv[1]
    ofile = sys.argv[2]

    contents = ""
    with open(ifile,"r") as fh:
        contents = fh.read()
    tokens = contents.split(" ")

    for i in range(0, len(tokens)):
        t = tokens[i]
        if(len(t) == 0):
            continue
        if(t[0] == "\\"):
            t = t.replace("[","_")
            t = t.replace("]","_")
            t = t.replace(".","_")
            t = t.replace("\\","_")
        tokens[i] = t
    
    towrite = " ".join(tokens)
    with open(ofile,"w") as fh:
        fh.write(towrite)

if(__name__=="__main__"):
    main()

