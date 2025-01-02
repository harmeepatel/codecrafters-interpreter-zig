const std = @import("std");
const print = std.debug.print;
const page_alloc = std.heap.page_allocator;

pub const TokenType = enum {
    AND,
    BANG,
    BANG_EQUAL,
    CLASS,
    COMMA,
    COMMENT,
    DOT,
    DOUBLE_QUOTE,
    ELSE,
    EOF,
    EQUAL,
    EQUAL_EQUAL,
    FALSE,
    FOR,
    FUN,
    GREATER,
    GREATER_EQUAL,
    IDENTIFIER,
    IF,
    LEFT_BRACE,
    LEFT_PAREN,
    LESS,
    LESS_EQUAL,
    MINUS,
    NEW_LINE,
    NIL,
    NUMBER,
    OR,
    PLUS,
    PRINT,
    RETURN,
    RIGHT_BRACE,
    RIGHT_PAREN,
    SEMICOLON,
    SLASH,
    SPACE,
    STAR,
    STRING,
    SUPER,
    TAB,
    THIS,
    TRUE,
    VAR,
    WHILE,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: []const u8,
    line: usize,
};

pub const TokenList = std.ArrayList(Token).init();

// func (tt TokenType) char1() rune {
// 	switch tt.Name {
// 	case "NEW_LINE":
// 		return '\n'
// 	case "TAB":
// 		return '\t'
// 	case "DOUBLE_QUOTE":
// 		return '"'
// 	}
// 	return rune(tt.Literal[0])
// }
//
// func (tt TokenType) char2() rune {
// 	if len(tt.Literal) > 1 {
// 		return rune(tt.Literal[1])
// 	}
// 	return -1
// }
//
// func (tt *TokenType) writeLiteral(literal string) {
// 	tt.Literal = literal
// }
//
// const NULL string = "null"
//
// var (
// 	BANG          TokenType = TokenType{"BANG", "!"}
// 	BANG_EQUAL    TokenType = TokenType{"BANG_EQUAL", "!="}
// 	COMMA         TokenType = TokenType{"COMMA", ","}
// 	COMMENT       TokenType = TokenType{"COMMENT", "//"}
// 	DOT           TokenType = TokenType{"DOT", "."}
// 	DOUBLE_QUOTE  TokenType = TokenType{"DOUBLE_QUOTE", "\""}
// 	EOF           TokenType = TokenType{"EOF", ""}
// 	EQUAL         TokenType = TokenType{"EQUAL", "="}
// 	EQUAL_EQUAL   TokenType = TokenType{"EQUAL_EQUAL", "=="}
// 	GREATER       TokenType = TokenType{"GREATER", ">"}
// 	GREATER_EQUAL TokenType = TokenType{"GREATER_EQUAL", ">="}
// 	IDENTIFIER    TokenType = TokenType{"IDENTIFIER", ""}
// 	LEFT_BRACE    TokenType = TokenType{"LEFT_BRACE", "{"}
// 	LEFT_PAREN    TokenType = TokenType{"LEFT_PAREN", "("}
// 	LESS          TokenType = TokenType{"LESS", "<"}
// 	LESS_EQUAL    TokenType = TokenType{"LESS_EQUAL", "<="}
// 	MINUS         TokenType = TokenType{"MINUS", "-"}
// 	NEW_LINE      TokenType = TokenType{"NEW_LINE", "\n"}
// 	NUMBER        TokenType = TokenType{"NUMBER", ""}
// 	PLUS          TokenType = TokenType{"PLUS", "+"}
// 	RIGHT_BRACE   TokenType = TokenType{"RIGHT_BRACE", "}"}
// 	RIGHT_PAREN   TokenType = TokenType{"RIGHT_PAREN", ")"}
// 	SEMICOLON     TokenType = TokenType{"SEMICOLON", ";"}
// 	SLASH         TokenType = TokenType{"SLASH", "/"}
// 	SPACE         TokenType = TokenType{"SPACE", " "}
// 	STAR          TokenType = TokenType{"STAR", "*"}
// 	STRING        TokenType = TokenType{"STRING", ""}
// 	TAB           TokenType = TokenType{"TAB", "\t"}
// )
// var (
// 	AND    TokenType = TokenType{"AND", "and"}
// 	CLASS  TokenType = TokenType{"CLASS", "class"}
// 	ELSE   TokenType = TokenType{"ELSE", "else"}
// 	FALSE  TokenType = TokenType{"FALSE", "false"}
// 	FOR    TokenType = TokenType{"FOR", "for"}
// 	FUN    TokenType = TokenType{"FUN", "fun"}
// 	IF     TokenType = TokenType{"IF", "if"}
// 	NIL    TokenType = TokenType{"NIL", "nil"}
// 	OR     TokenType = TokenType{"OR", "or"}
// 	PRINT  TokenType = TokenType{"PRINT", "print"}
// 	RETURN TokenType = TokenType{"RETURN", "return"}
// 	SUPER  TokenType = TokenType{"SUPER", "super"}
// 	THIS   TokenType = TokenType{"THIS", "this"}
// 	TRUE   TokenType = TokenType{"TRUE", "true"}
// 	VAR    TokenType = TokenType{"VAR", "var"}
// 	WHILE  TokenType = TokenType{"WHILE", "while"}
// )
//
// type Token struct {
// 	Type    TokenType
// 	Lexeme  string
// 	Literal string
// 	Line    uint
// }
//
// type TokenList []Token
//
// func (tl *TokenList) print() {
// 	for _, t := range *tl {
// 		t.print()
// 	}
// }
// func (tl *TokenList) append(t Token) {
// 	*tl = append(*tl, t)
// }
//
// func NewToken(ttype TokenType, lexeme, literal string) *Token {
// 	return &Token{
// 		Type:    ttype,
// 		Lexeme:  lexeme,
// 		Literal: literal,
// 	}
// }
//
// func (t *Token) print() {
// 	tl := NULL
// 	tle := t.Lexeme
// 	if t.Literal != "" {
// 		tl = t.Literal
// 	}
// 	switch t.Type.Name {
// 	case "STRING":
// 		tle = `"` + tle + `"`
// 		break
// 	case "NUMBER":
// 		dn, err := strconv.ParseFloat(t.Lexeme, 64)
// 		if err != nil {
// 			os.Exit(65)
// 		}
// 		tdn := math.Trunc(dn)
// 		if dn == tdn {
// 			if len(t.Lexeme)+1 > len(strconv.FormatFloat(dn, 'g', -1, 64)) {
// 			}
// 			tl = fmt.Sprintf("%.1f", dn)
// 		} else {
// 			tl = strconv.FormatFloat(dn, 'g', -1, 64)
// 		}
// 		tle = t.Lexeme
// 		break
// 	}
// 	// println("print: %s  %s  %s", t.Type.Name, tle, tl)
// 	fmt.Println(t.Type.Name, tle, tl)
// }
