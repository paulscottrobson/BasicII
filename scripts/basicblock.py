# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		basicblock.py
#		Purpose :	Basic code block manipulator
#		Date :		29th May 2018
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re
from gentokens import *
from tokeniser import *

# *******************************************************************************************
#
#										Basic Block Object
#
# *******************************************************************************************

class BasicBlock(object):
	def __init__(self,baseAddress = 0x0000,size = 0xFFFF,debug = True):
		self.baseAddress = baseAddress									# Block information
		self.blockSize = size
		self.endAddress = baseAddress + size
		self.data = [ 0 ] * size 										# containing data
		for i in range(0,4):											# set 4 byte header
			self.data[i] = ord("BASC"[i])
		self.debug = False
		self.clearMemory()												# same as clear
		self.memoryVariableCreated = False 								# allocated memory
		self.debug = debug

	def clearMemory(self):
		for v in range(ord('@'),ord('Z')+1):							# zero fast variables
			self.setFastVariable(chr(v),0)
		self.writeWord(self.baseAddress+0xA0,self.baseAddress+0xC8)		# reset low memory
		self.writeWord(self.baseAddress+0xA2,self.endAddress)			# reset high memory
		self.writeWord(self.baseAddress+0xC0,0x0000)					# erase program

	def setFastVariable(self,variable,value):
		assert re.match("^[\\@A-Z]$",variable) is not None
		value = value & 0xFFFFFFFF
		self.writeWord(self.baseAddress+(ord(variable)-ord('@'))*4+4,value & 0xFFFF)
		self.writeWord(self.baseAddress+(ord(variable)-ord('@'))*4+6,value >> 16)

	def allocateLowMemory(self,count):
		addr = self.readWord(self.baseAddress+0xA0)
		self.writeWord(self.base+0xA0+count)
		assert self.readWord(self.baseAddress+0xA0) < self.readWord(self.baseAddress+0xA2)
		return addr 

	def allocateHighMemory(self,count):
		addr = self.readWord(self.baseAddress+0xA2) - count
		self.writeWord(self.baseAddress+0xA2,addr)
		assert self.readWord(self.baseAddress+0xA0) < self.readWord(self.baseAddress+0xA2)

	def readWord(self,addr):
		assert addr >= self.baseAddress and addr <= self.endAddress
		addr = addr - self.baseAddress
		return self.data[addr] + self.data[addr] * 256

	def writeWord(self,addr,data):
		assert addr >= self.baseAddress and addr <= self.endAddress
		data = data & 0xFFFF
		self.data[addr-self.baseAddress] = data & 0xFF
		self.data[addr-self.baseAddress+1] = data >> 8
		if self.debug:
			print("{0:04x} {1:04x}".format(addr,data))


if __name__ == "__main__":
	blk = BasicBlock(0x4000,0x8000)
