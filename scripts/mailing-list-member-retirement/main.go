package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"github.com/emersion/go-mbox"
	"github.com/emersion/go-message/mail"
	_ "github.com/emersion/go-message/charset"
)

// Prints the email addresses (one per line) of all senders by parsing an MBOX.

func main() {
	mboxNamePtr := flag.String("mbox", "test.mbox", "MBOX to read")
	flag.Parse()
	PrintAllMboxSenders(*mboxNamePtr)
}

func PrintAllMboxSenders(fileName string) {
	f, err := os.Open(fileName)
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err = f.Close(); err != nil {
			log.Fatal(err)
		}
	}()
	fr := bufio.NewReader(f)
	mr := mbox.NewReader(fr)
	for {
		r, err := mr.NextMessage()
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatal(err)
		}
		PrintMessageSender(r)
	}
}

func PrintMessageSender(r io.Reader) {
	mr, err := mail.CreateReader(r)
	if err != nil {
		IgnoreMail(err, mr)
	}

	addr, err := mr.Header.AddressList("From")
	if err != nil {
		IgnoreMail(err, mr)
		return
	} else if len(addr) != 1 {
		IgnoreMail(fmt.Errorf("unexpected number of senders: %v", len(addr)), mr)
		return
	}
	fmt.Println(addr[0].Address)
}

func IgnoreMail(err error, mailReader *mail.Reader) {
	reason := err.Error()
	id, _ := mailReader.Header.MessageID()
	fmt.Fprintf(os.Stderr, "Warning: Ignored a mail with ID \"%v\" for the reason \"%v\".\n", id, reason)
}
