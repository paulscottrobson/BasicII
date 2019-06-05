# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		basicblock.py
#		Purpose :	Basic code block manipulator
#		Date :		2nd July 2018
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re,os,sys
from gentokens import *
from tokeniser import *

# *******************************************************************************************
#
#										Basic Block Object
#
# *******************************************************************************************

class BasicBlock(object):
	def __init__(self,baseAddress = 0x0000,size = 0xFFFF,debug = False):
		self.baseAddress = baseAddress											# Block information
		self.blockSize = size
		self.endAddress = baseAddress + size
		self.data = [ 0 ] * size 												# containing data
		self.debug = False
		self.clearMemory()														# same as clear
		self.memoryVariableCreated = False 										# allocated memory
		self.debug = debug
		self.tokeniser = Tokeniser()											# tokenises things
		self.variables = {}														# variable info
		self.lastProgramLineNumber = 0
		if BasicBlock.HASHTABLESIZE != 0x20:
			print("*** WARNING ***")
			print("The hash table size per type has changed. This is calculated in")
			print("variable.asm *not* using this constant value.")
			assert False
	#
	#		Import 
	#
	def importFile(self,fileName):
		h = open(fileName,"rb")
		self.data = bytes(h.read(-1))
		h.close()
	#
	#		Write binary out
	#
	def exportFile(self,fileName):
		h = open(fileName,"wb")
		h.write(bytes(self.data))
		h.close()
	#
	#		Erase all variables and code
	#
	def clearMemory(self):
		for i in range(0,len(self.data)):										# Erase the data
			self.data[i] = 0
		for i in range(0,4):													# set 4 byte header
			self.data[i] = ord(BasicBlock.ID[i])
		self.writeWord(self.baseAddress+BasicBlock.HIGHPTR,self.endAddress)		# reset high memory
		self.writeWord(self.baseAddress+BasicBlock.PROGRAM,0x0000)				# erase program
		self.resetLowMemory()
	#
	#		Rewrite the spacer and low memory
	#
	def resetLowMemory(self):
		ptr = self.baseAddress+BasicBlock.PROGRAM 								# Where code starts
		while self.readWord(ptr) != 0x0000:										# follow the code link chain
			ptr = ptr + self.readWord(ptr)
		self.writeWord(ptr+2,0xEEEE)											# write EEEE twice after it
		self.writeWord(ptr+4,0xEEEE)
		self.writeWord(self.baseAddress+BasicBlock.LOWPTR,ptr+6)				# free memory starts here.		
		return ptr 																# return where next line goes
	#
	#		Allocate low memory (e.g. from program end up)
	#
	def allocateLowMemory(self,count):
		addr = self.readWord(self.baseAddress+BasicBlock.LOWPTR)				# address to use
		self.writeWord(self.baseAddress+BasicBlock.LOWPTR,addr+count)			# update offset
		assert self.readWord(self.baseAddress+BasicBlock.LOWPTR) < self.readWord(self.baseAddress+BasicBlock.HIGHPTR)
		return addr 
	#
	#		Allocate high memory (e.g. from top down)
	#
	def allocateHighMemory(self,count):
		addr = self.readWord(self.baseAddress+BasicBlock.HIGHPTR) - count		# address to use
		self.writeWord(self.baseAddress+BasicBlock.HIGHPTR,addr)				# update new high address
		assert self.readWord(self.baseAddress+BasicBlock.LOWPTR) < self.readWord(self.baseAddress+BasicBlock.HIGHPTR)
		return addr
	#
	#		Read a word from memory
	#
	def readWord(self,addr):
		assert addr >= self.baseAddress and addr <= self.endAddress
		addr = addr - self.baseAddress
		return self.data[addr] + self.data[addr+1] * 256
	#
	#		Write a word to memory
	#
	def writeWord(self,addr,data):
		assert addr >= self.baseAddress and addr <= self.endAddress
		data = data & 0xFFFF
		self.data[addr-self.baseAddress] = data & 0xFF
		self.data[addr-self.baseAddress+1] = data >> 8
		if self.debug:
			print("{0:04x} {1:04x}".format(addr,data))
	#
	#		Read long as signed int
	#
	def readLong(self,addr):
		val = self.readWord(addr)+(self.readWord(addr+2)<<16)
		if (val & 0x80000000) != 0:
			val = val - 0x100000000
		return val
	#
	#		Create a representation of an identifier in high memory. We do this because
	#		normally we use the one in the program, but they are created seperately.
	#
	def createIdentifierReference(self,name):
		assert re.match("^[A-Z][A-Z0-9]*\\$?\\(?$",name.upper()) is not None 	# check legal variable name
		assert len(name) > 1													# check not fast variable
		tokens = self.tokeniser.tokenise(name)									# tokenise it
		addr = self.allocateHighMemory(len(tokens)*2)							# allocate high mem for name
		for i in range(0,len(tokens)):											# copy it (normally in program)
			self.writeWord(addr+i*2,tokens[i])
		return addr
	#
	#		Create a BASIC string in high memory.
	#
	def createString(self,s):
		s = [ord(x) for x in chr(len(s))+s ]									# convert to numbers
		mem = self.allocateHighMemory(len(s)+2)									# +2 because we wordwrite.
		for i in range(0,len(s)):												# copy string out.
			self.writeWord(mem+i,s[i])		
		return mem
	#
	#		Add a line of BASIC
	#
	def addBASICLine(self,lineNumber,code):
		assert not self.memoryVariableCreated									# check not created variables
		if lineNumber is None or lineNumber == 0:								# default line number
			lineNumber = self.lastProgramLineNumber + 1
		assert lineNumber > self.lastProgramLineNumber and lineNumber <= 32767 	# check line number
		pos = self.resetLowMemory()												# where does it go
		self.lastProgramLineNumber = lineNumber 								# remember last
		codeLine = self.tokeniser.tokenise(code) 								# convert to tokens
		codeLine.append(0)														# EOL
		codeLine.insert(0,lineNumber|0x8000) 									# insert line number
		codeLine.insert(0,len(codeLine)*2+2)									# skip
		codeLine.append(0)														# final program end marker
		for t in codeLine:														# write it out
			self.writeWord(pos,t)  
			pos += 2
		self.resetLowMemory() 													# and reset low memory
	#
	#		Add a variable (multiple front ends). Names and string contents are allocated
	#		in high memory as the nearest simulation.
	#
	#		AddInteger has a special case (the fast variables) when A-Z used.
	#
	def addInteger(self,name,defaultValue):
		if len(name) == 1:
			self.writeFastVariable(name,defaultValue)
		else:
			self._addVariable(name,0,defaultValue,0)
	def addString(self,name,defaultValue):
		self._addVariable(name,2,defaultValue,0)
	def addIntegerArray(self,name,defaultValue,highIndex):
		self._addVariable(name,1,defaultValue,highIndex)
	def addStringArray(self,name,defaultValue,highIndex):
		self._addVariable(name,3,defaultValue,highIndex)
	#
	def _addVariable(self,name,typeID,defaultValue,highIndex):
		self.memoryVariableCreated = True 										# can't add more program
		assert name != "" and typeID >= 0 and typeID <= 3
		tName = self.tokeniser.tokenise(name)									# tokenise name.
		assert ((tName[0] >> 11) & 3) == typeID									# check types match.
		tAddress = self.createIdentifierReference(name) 						# get reference to name
		hashEntry = self.getHashTableAddress(tName[0])							# get hash pointer.
		#
		variable = self.allocateLowMemory(6+(highIndex+1) * 4)					# Allocate memory.
		self.writeWord(variable+0,self.readWord(hashEntry))						# link is previous head
		self.writeWord(variable+2,tAddress)										# name of variable.
		self.writeWord(variable+4,highIndex)									# highest index.
		self.writeWord(hashEntry,variable)										# Link into list head				
		#
		for i in range(0,highIndex+1):											# erase the data.
			addr = variable + 6 + i * 4 										# where it goes.
			if typeID < 2:														# integer.
				defaultValue = defaultValue & 0xFFFFFFFF
				self.writeWord(addr,defaultValue & 0xFFFF)
				self.writeWord(addr+2,defaultValue >> 16)
				defaultValue += 0x10000
			else:
				string = "{0}.{1}".format(defaultValue,i)						# create string to store
				if highIndex == 0:
					string = defaultValue
				self.writeWord(addr,self.createString(string))					# store address
				self.writeWord(addr+2,0)										# upper address is zero.
	#
	#		Write constant to fast variable.
	#
	def writeFastVariable(self,name,value):
		name = name.upper()
		assert len(name) == 1 and name >= "A" and name <= "Z"
		addr = (ord(name[0])-ord('A'))*4+BasicBlock.FASTVARIABLES+self.baseAddress
		value = value & 0xFFFFFFFF
		self.writeWord(addr,value & 0xFFFF)
		self.writeWord(addr+2,value >> 16)
	#
	#		Get the hash entry from the first word of the token.
	#
	def getHashTableAddress(self,firstToken):
		typeID = (firstToken >> 11) & 3 										# type 0-3.
		address = BasicBlock.HASHTABLE+BasicBlock.HASHTABLESIZE*typeID 			# address of hash table start
		address = address + (firstToken & BasicBlock.HASHMASK) * 2 				# position in that table
		return address+self.baseAddress
	#
	#		Export constants
	#
	def exportConstants(self,fileName):
		self.handle = open(fileName.replace("/",os.sep),"w")
		self._export("BlockFastVariables",BasicBlock.FASTVARIABLES)
		self._export("BlockLowMemoryPtr",BasicBlock.LOWPTR)
		self._export("BlockHighMemoryPtr",BasicBlock.HIGHPTR)
		self._export("BlockHashTable",BasicBlock.HASHTABLE)
		self._export("BlockHashTableSize",BasicBlock.HASHTABLESIZE)
		self._export("BlockHashMask",BasicBlock.HASHMASK)
		self._export("BlockProgranStart",BasicBlock.PROGRAM)
		self.handle.close()
	#
	def _export(self,name,value):
		self.handle.write("{0} = ${1:04x}\n".format(name,value))
	#
	#		List variables.
	#
	def listVariables(self,handle = sys.stdout):
		types = [ "","()","$","$()" ]
		for typeID in range(0,4):												# Type range 0-4
			for hashID in range(0,BasicBlock.HASHMASK+1): 						# Hash entries
				hashPtr = self.baseAddress+BasicBlock.HASHTABLE+typeID*BasicBlock.HASHTABLESIZE+hashID*2
				ptr = self.readWord(hashPtr)									# fist entry.
				if ptr != 0:
					handle.write("{0}{1} Hash:{2} ${3:04x}\n".format("Integer" if typeID < 2 else "String","" if typeID % 2 == 0 else " Array",hashID,hashPtr))
					while ptr != 0:
						handle.write("\t${3:04x} {0:10} {1:3} [{2}]\n".format(self.extractName(self.readWord(ptr+2))+types[typeID],self.readWord(ptr+4),self.getData(ptr+6,self.readWord(ptr+4),typeID >= 2),ptr))
						ptr = self.readWord(ptr)
					handle.write("\n")
	#
	#		Convert tokenised name to text.
	#
	def extractName(self,addr):
		done = False
		s = ""
		while not done:
			token = self.readWord(addr)
			done = (token & 0x2000) == 0
			token = token & 0x7FF
			s = s + self.toASCII(token % 45)+self.toASCII(int(token/45)%45)
			addr += 2
		return s
	#
	#		Get data
	#
	def getData(self,address,count,isString):
		dataList = [self.readLong(address+4*x) for x in range(0,count+1)]
		if isString:
			dataList = ['"'+self.readString(x)+'"' for x in dataList]
		else:
			dataList = ["${0:x}".format(x) for x in dataList]
		return ",".join(dataList)
	#
	def toASCII(self,c):
		if c >= 1 and c <= 26:
			return chr(c+96)
		return "" if c == 0 else str(c-27)
	#
	def readString(self,ptr):
		count = self.readWord(ptr) & 0xFF
		s = [self.readWord(ptr+i+1) & 0xFF for i in range(0,count)]
		return "".join([chr(x) for x in s])

BasicBlock.ID = "BASC"															# ID
BasicBlock.FASTVARIABLES = 0x04 												# Fast Variable Base
BasicBlock.LOWPTR = 0x70 														# Low Memory Allocation
BasicBlock.HIGHPTR = 0x72 														# High Memory Allocation
BasicBlock.PROGRAM = 0x100 														# First line of program
BasicBlock.HASHTABLE = 0x80 													# Hash Table Base
BasicBlock.HASHTABLESIZE = 0x20 												# Bytes for each hash table
BasicBlock.HASHMASK = 15 														# Hash mask (0,1,3,7,15)

if __name__ == "__main__":
	blk = BasicBlock(0x4000,0x8000)
	blk.addBASICLine(10,'a=len(strarr01$(0)+"---"+strarr01$(2)+"---"+sx1$)')
	blk.addInteger("minus2",-2)
	blk.addInteger("x",44)
	blk.addInteger("y",65540)
	blk.addInteger("i1",-42)
	blk.addInteger("i1x",3142)
	blk.addString("sx1$","this is a string")
	blk.addIntegerArray("iar1(",132142,4)
	blk.addStringArray("strarr01$(","ast",3)
	blk.exportFile("temp/basic.bin")	
	blk.exportConstants("temp/block.inc")
	blk.listVariables()

