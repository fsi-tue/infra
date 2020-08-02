package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
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
		if err.Error() == "charset \"cp-850\": ianaindex: invalid encoding name" {
			fmt.Fprintf(os.Stderr, "Ignored a mail due to an invalid charset\n")
			return // TODO: Print message ID
		}
		log.Fatal(err)
	}

	addr, err := mr.Header.AddressList("From")
	if err != nil {
		if strings.Contains(err.Error(), "invalid utf-8 in quoted-string") {
			addr := strings.TrimPrefix(err.Error(), "mail: missing word in phrase: mail: invalid utf-8 in quoted-string: ")
			fmt.Fprintf(os.Stderr, "Ignored due to invalid UTF-8 encoding: %v\n", addr)
			return
		} else if err.Error() == "mail: missing @ in addr-spec" {
			fmt.Fprintf(os.Stderr, "Ignored a sender due to missing @\n")
			return // TODO: Print invalid address
		} else if err.Error() == "mail: no angle-addr" {
			fmt.Fprintf(os.Stderr, "Ignored a mail due to no angle-address\n")
			return // TODO: Print message ID
		}
		log.Fatal(err)
	} else if len(addr) != 1 {
		if len(addr) == 0 {
			fmt.Fprintf(os.Stderr, "Ignored a mail due to a missing sender\n")
			return // TODO: Print message ID
		}
		fmt.Fprintf(os.Stderr, "A mail has an unexpected number of senders: %v\n", len(addr))
		return // TODO: Print message ID
	}
	fmt.Println(addr[0].Address)
}
