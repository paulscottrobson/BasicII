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
	#
	#	Write binary out
	#
	def export(self,fileName):
		h = open(fileName,"wb")
		h.write(bytes(self.data))
		h.close()
	#
	#	Erase all variables and code
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
	#	Rewrite the spacer and low memory
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
	#	Allocate low memory (e.g. from program end up)
	#
	def allocateLowMemory(self,count):
		addr = self.readWord(self.baseAddress+BasicBlock.LOWPTR)				# address to use
		self.writeWord(self.baseAddress+BasicBlock.LOWPTR,addr+count)			# update offset
		assert self.readWord(self.baseAddress+BasicBlock.LOWPTR) < self.readWord(self.baseAddress+BasicBlock.HIGHPTR)
		return addr 
	#
	#	Allocate high memory (e.g. from top down)
	#
	def allocateHighMemory(self,count):
		addr = self.readWord(self.baseAddress+BasicBlock.HIGHPTR) - count		# address to use
		self.writeWord(self.baseAddress+BasicBlock.HIGHPTR,addr)				# update new high address
		assert self.readWord(self.baseAddress+BasicBlock.LOWPTR) < self.readWord(self.baseAddress+BasicBlock.HIGHPTR)
		return addr
	#
	#	Read a word from memory
	#
	def readWord(self,addr):
		assert addr >= self.baseAddress and addr <= self.endAddress
		addr = addr - self.baseAddress
		return self.data[addr] + self.data[addr+1] * 256
	#
	#	Write a word to memory
	#
	def writeWord(self,addr,data):
		assert addr >= self.baseAddress and addr <= self.endAddress
		data = data & 0xFFFF
		self.data[addr-self.baseAddress] = data & 0xFF
		self.data[addr-self.baseAddress+1] = data >> 8
		if self.debug:
			print("{0:04x} {1:04x}".format(addr,data))
	#
	#	Read long as signed int
	#
	def readLong(self,addr):
		val = self.readWord(addr)+(self.readWord(addr+2)<<16)
		if (val & 0x80000000) != 0:
			val = val - 0x100000000
		return val
	#
	#	Create a representation of an identifier in high memory.
	#
	def createIdentifierReference(self,name):
		assert re.match("^[\\@A-Z][\\@A-Z0-9]*$",name.upper()) is not None 		# check legal variable name
		assert len(name) > 1													# check not fast variable
		tokens = self.tokeniser.tokenise(name)									# tokenise it
		addr = self.allocateHighMemory(len(tokens)*2)							# allocate high mem for name
		for i in range(0,len(tokens)):											# copy it (normally in program)
			self.writeWord(addr+i*2,tokens[i])
		return addr
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
	#		Export constants
	#
	def exportConstants(self,fileName):
		self.handle = open(fileName.replace("/",os.sep),"w")
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

BasicBlock.ID = "BASC"															# ID
BasicBlock.FASTVARIABLES = 0x04 												# Fast Variable Base
BasicBlock.LOWPTR = 0x04 														# Low Memory Allocation
BasicBlock.HIGHPTR = 0x06 														# High Memory Allocation
BasicBlock.PROGRAM = 0xC0 														# First line of program
BasicBlock.HASHTABLE = 0x20 													# Hash Table Base
BasicBlock.HASHTABLESIZE = 0x20 												# Bytes for each hash table
BasicBlock.HASHMASK = 15 														# Hash mask (0,1,3,7,15)

if __name__ == "__main__":
	blk = BasicBlock(0x4000,0x8000)
	blk.addBASICLine(10,"a=4")
	blk.addBASICLine(20,"let a=42")
	blk.export("temp/basic.bin")	
	blk.exportConstants("temp/block.inc")
