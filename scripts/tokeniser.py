# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		tokenise.py
#		Purpose :	Converts string into a list of tokens.
#		Date :		2nd June 2018
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re
from gentokens import *

# *******************************************************************************************
#
#									Tokeniser worker class
#
# *******************************************************************************************

class Tokeniser(object):
	def __init__(self):
		if Tokeniser.tokens is None:
			Tokeniser.tokens = [x for x in TokenList().getList() ]	# get tokens
			Tokeniser.tokens.sort(key = lambda x:-len(x.name))		# sort by name, longest first
	#
	#		Tokenise a string into an array of words
	#
	def tokenise(self,s):
		self.buffer = []
		s = s.strip()
		while s != "":
			s = self.tokeniseOne(s).strip()
		return self.buffer
	#
	#		Tokenise one item - a token, constant, identifier or quoted string.
	#
	def tokeniseOne(self,s):
		t = self.findToken(s) 										# find a matching token
		if t is not None:
			self.buffer.append(t.id)								# add the token ID.
			return s[len(t.name):]									# return post token.
		#
		m = re.match("^(\\d+)(.*)$",s)								# constant
		if m is not None:
			value = int(m.group(1))									# value of constant
			assert value < 32768 * 4096,"Out of range "+s 			# too big.
			if value >= 32768: 										# constant shift ?
				self.buffer.append((value >> 15) | 0x1000)
			self.buffer.append((value & 0x7FFF) | 0x8000)			# number token
			return m.group(2)
		#
		m = re.match("^([a-z][a-z0-9]*)(\\$?)(\\(?)(.*)$",s.lower())# identifier.
		if m is not None:
			ident = [self.convert(x) for x in m.group(1).upper()]	# convert to legal values
			itype = 0 if m.group(2) == "" else 0x1000
			itype = itype if m.group(3) == "" else itype+0x800
			if len(ident) % 2 != 0:									# pad out to even length using zero.
				ident.append(0) 									# 000000 is padding character.
			for i in range(0,len(ident)-1,2):
				word = ident[i] + ident[i+1] * 45
				assert word >= 0 and word < 2048
				word = word + 0x4000 + itype
				if i != len(ident)-2: 								# add continuation marker.
					word = word + 0x2000
				self.buffer.append(word)
			return m.group(4)
		#
		m = re.match('^\\"(.*?)\\"(.*)$',s)							# quoted string.
		if m is not None:
			string = m.group(1)
			assert len(string) < 252,"String too long "+s			
			string = [ord(c) for c in string]						# byte string.
			string.insert(0,len(string))							# make string length prefixed.
			if len(string) % 2 != 0: 								# pad out to even length.
				string.append(0)
			self.buffer.append(0x0000+(len(string) >> 1)*2+2)		# header with object length.
			for i in range(0,len(string),2):						# followed by the data.
				self.buffer.append(string[i] + (string[i+1] << 8))
			return m.group(2)
		#
		assert False,"Can't tokenise '{0}'".format(s)			
	#
	#		Convert character to char in range 0-44
	#
	def convert(self,c):
		c = c.upper()
		if c >= 'A' and c <= 'Z':									# A-Z 1-26
			return ord(c)-ord('A')+1
		if c >= '0' and c <= '9':									# 0-9 27-36
			return int(c)+27
		assert False
	#
	#		Find the token that s begins with. Relies on sort order of tokeniser.tokens
	#
	def findToken(self,s):
		s = s.lower()												# all tokens are L/C
		for e in Tokeniser.tokens:
			if s.startswith(e.name):
				return e
		return None
	#
	#		Debugging helper
	#
	def tokeniseDebug(self,s):
		print("**** "+s+" ****")
		r = self.tokenise(s)
		for b in r:
			print("${0:04x}".format(b))

Tokeniser.tokens = None

if __name__ == "__main__":
	tk = Tokeniser()
	tk.tokeniseDebug('len( let 32769 45')
	tk.tokeniseDebug('abc: 0')
	tk.tokeniseDebug('a$: 0')
	tk.tokeniseDebug('c(:) 0')
	tk.tokeniseDebug('zzzz$(: 0')
	tk.tokeniseDebug('z')
