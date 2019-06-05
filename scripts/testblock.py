# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		testblock.py
#		Purpose :	Test Block which creates variables etc.
#		Date :		5th July 2018
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re,os,sys,random
from basicblock import *

class TestBlock(BasicBlock):
	def __init__(self,iCount,sCount,iaCount,saCount,seed = 42):
		BasicBlock.__init__(self,0x4000,0x8000)
		random.seed(seed)
		self.variables = []
		self.identifiers = {}
		self.arrays = {}
		for i in range(0,iCount):
			self.variables.append(self.createVariable(False))
		for i in range(0,sCount):
			self.variables.append(self.createVariable(True))

	def createVariable(self,isString):
		isOk = False
		while not isOk:
			name = self.createIdentifier("$" if isString else "")
			isOk = not (name in self.identifiers)
		self.identifiers[name] = True

		defn = { "isstring":isString,"name":name }
		if isString:
			value = self.createIdentifier("",2,8)+"-"+name
			defn["value"] = '"'+value+'"'
			self.addLine('let {0} = "{1}"'.format(name,value))
		else:
			value = random.randint(0,0x00FFFFF)
			if random.randint(0,4) == 0:
				value = value & 0xFF
				if random.randint(0,4) == 0:
					value = value & 0xF
			if random.randint(0,1) == 0:
				value = -value
			defn["value"] = value
			self.addLine("let {0} = {1}".format(name,value))
		return defn

	def createIdentifier(self,postFix,fromSize=1,toSize=4):
		length = random.randint(fromSize,toSize)
		name = ""
		for i in range(0,length):
			if i == 0 or random.randint(1,3) != 3:
				name = name + chr(random.randint(65,90))
			else:
				name = name + chr(random.randint(48,57))
		return (name+postFix).lower()

	def addLine(self,code):
		self.addBASICLine(None,code)
		#print("{0:5} {1}".format(self.lastProgramLineNumber,code))

	def getNumber(self):
		return self._getVariable(False)
	def getString(self):
		return self._getVariable(True)

	def _getVariable(self,isString):
		isOk = False
		while not isOk:
			element = self.variables[random.randint(0,len(self.variables)-1)]
			isOk = element["isstring"] == isString
		return element

if __name__ == "__main__":
	n = 256
	blk = TestBlock(64,64,0,0)
	for i in range(0,n):
		v = blk.getNumber()
		blk.addLine('assert {0} = {1}'.format(v["name"],v["value"]))
		v = blk.getString()
		blk.addLine('assert {0} = {1}'.format(v["name"],v["value"]))
	blk.exportFile("temp/basic.bin")	
	blk.listVariables()
	print(blk.resetLowMemory())