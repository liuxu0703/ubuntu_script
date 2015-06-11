#!/usr/bin/python

# AUTHOR : liuxu-0703@163.com
# used to extract keyword sets from xml
# used by aplog_helper.sh and adblogcat.sh

import os
import sys
import getopt
from xml.dom.minidom import parse, parseString

#=======================================

class KeywordSet:
    
    def __init__(self, xml_node):
        self.name = self.getText(xml_node.getElementsByTagName('name')[0])
        self.type = self.getText(xml_node.getElementsByTagName('type')[0])

        active = self.getText(xml_node.getElementsByTagName('active')[0])
        if active == 'true':
            self.active = True
        else:
            self.active = False

        try:
            self.project = self.getText(xml_node.getElementsByTagName('project')[0])
        except:
            self.project = 'None'
        
        self.keywords = []
        self.readKeywords(xml_node.getElementsByTagName('keywords')[0])
        

    def getText(self, text_node):
        '''get text from xml node
        $text_node should be a node with type NODE_TEXT
        return str of the text
        '''
        ret = ''
        for n in text_node.childNodes:
            ret = ret + n.nodeValue
        return ret


    def readKeywords(self, keywords_node):
        '''read keywords and store them in self.keywords
        $keywords_node should be xml node with name of <keywords>
        return none
        '''
        for n in keywords_node.getElementsByTagName('k'):
            self.keywords.append(self.getText(n))

        
    def printKeywords(self):
        '''print all keywords in self.keywords
        return none
        '''
        for k in self.keywords:
            print k


    def printAllInfo(self):
        print 'name: ' + self.name
        print 'type: ' + self.type
        print 'proj: ' + self.project
        print 'acti: ' + str(self.active)
        word_str = ''
        for k in self.keywords:
            word_str = word_str + k + '; '
        print 'keywords:'
        print word_str
        print ' '

#=======================================

class KeywordManager:

    def __init__(self, path):
        if not os.path.isfile(path):
            print '*. cannot find keywordset.xml file !'
            return
        
        self.path = path
        self.xml_doc = parse(self.path)
        self.xml_ksm = self.xml_doc.getElementsByTagName('KeywordSetManager')[0]
        self.xml_ks_list = self.xml_ksm.getElementsByTagName('keywordset')
        self.keywordset_list = []
        self.print_inactive = False

        for node in self.xml_ks_list:
            #print self.getText(node.getElementsByTagName('name')[0])
            self.readKeywordSet(node)

        self.keywordset_list.sort(lambda x,y: self.compare(x, y))


    def compare(self, a, b):
        '''compare between two KeywordSet instance
        $a and $b should be instance of KeywordSet
        return -1, 0, 1
        '''
        if a.type != b.type:
            if a.type == 'include':
                return -1
            if a.type == 'exclude':
                return 1

        if a.project != b.project:
            if a.project == 'None':
                return -1
            if b.project == 'None':
                return 1
        
        cmp_result = cmp(a.project, b.project)
        if cmp_result != 0:
            return cmp_result

        return cmp(a.name, b.name)


    def getText(self, text_node):
        '''get text from xml node
        $text_node should be a node with type NODE_TEXT
        return str of the text
        '''
        r = ''
        for n in text_node.childNodes:
            r = r + n.nodeValue
        return r


    #param $node should be a 'keywordset' node in xml file
    def readKeywordSet(self, node):
        '''read keywords and store them in self.keywordset_list
        $keywords_node should be xml node twith name of <keywordset>
        return none
        '''
        ks = KeywordSet(node)
        self.keywordset_list.append(ks)


    #param should be true or false
    def setPrintInactiveEnabled(self, inactive):
        '''set self.print_inactive
        '''
        self.print_inactive = inactive


    def listSets(self):
        '''print all keywordsets
        '''
        for ks in self.keywordset_list:
            if ks.active or self.print_inactive:
                print ks.name       


    #param $set_type should be either include or exclude
    def listSetsByType(self, set_type):
        '''list keywordsets by include/exclude type
        '''
        for ks in self.keywordset_list:
            if ks.type == set_type:
                if ks.active or self.print_inactive:
                    print ks.name


    #param $set_name should be name of a keywordset
    def printKeywordsBySetName(self, set_name):
        '''list keywords in a keywordset by name
        if more than one keywordsets are with the same name, print them all
        '''
        for ks in self.keywordset_list:
            if ks.name == set_name:
                if ks.active or self.print_inactive:
                    ks.printKeywords()


if __name__ == '__main__':
    km = KeywordManager(sys.path[0] + os.sep + '/keywordset.xml')
    opts, args = getopt.getopt(sys.argv[1:], 't:n:d')
    
    for op, value in opts:
        if op == '-t':
            km.listSetsByType(value)
        elif op == '-n':
            km.printKeywordsBySetName(value)
        elif op == '-d':
            for ks in km.keywordset_list:
                ks.printAllInfo()
