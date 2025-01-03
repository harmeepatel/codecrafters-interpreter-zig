const std = @import("std");
const Token = @import("Token.zig");
const TokenType = Token.TokenType;
const TokenList = Token.TokenList;
const Literal = Token.Literal;
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const page_alloc = std.heap.page_allocator;

const ScannerError = error{UnexpectedError};
const Self = @This();

icurr: usize,
line: usize,
skipChar: bool,
skipNext: usize,
source: []const u8,
tokenList: TokenList,
scanError: ?ScannerError,

pub fn New(source: []const u8) Self {
    return Self{
        .icurr = 0,
        .line = 1,
        .skipChar = false,
        .skipNext = 0,
        .source = source,
        .tokenList = TokenList.init(page_alloc),
        .scanError = null,
    };
}

fn peek(self: Self) u8 {
    if (self.icrr < self.source.len - 1) {
        return self.source[self.icurr + 1];
    }
}

pub fn print(self: Self) void {
    for (self.tokenList.items) |token| {
        token.print();
    }
    if (self.scanError) |err| {
        if (err == error.UnexpectedError) {
            std.process.exit(65);
        }
    }
}

pub fn scan(self: *Self) !void {
    for (self.source, 0..) |char, i| {
        self.icurr = i;
        if (self.skipChar) {
            self.skipChar = false;
            continue;
        }
        // while (self.skipNext
        switch (char) {
            '(' => try self.tokenList.append(Token.New(TokenType.LEFT_PAREN, "(", Literal.None())),
            ')' => try self.tokenList.append(Token.New(TokenType.RIGHT_PAREN, ")", Literal.None())),
            '{' => try self.tokenList.append(Token.New(TokenType.LEFT_BRACE, "{", Literal.None())),
            '}' => try self.tokenList.append(Token.New(TokenType.RIGHT_BRACE, "}", Literal.None())),
            ',' => try self.tokenList.append(Token.New(TokenType.COMMA, ",", Literal.None())),
            '.' => try self.tokenList.append(Token.New(TokenType.DOT, ".", Literal.None())),
            '-' => try self.tokenList.append(Token.New(TokenType.MINUS, "-", Literal.None())),
            '+' => try self.tokenList.append(Token.New(TokenType.PLUS, "+", Literal.None())),
            ';' => try self.tokenList.append(Token.New(TokenType.SEMICOLON, ";", Literal.None())),
            '*' => try self.tokenList.append(Token.New(TokenType.STAR, "*", Literal.None())),
            else => {
                dbg_print("[line {}] Error: Unexpected character: {c}\n", .{ self.line, char });
                self.scanError = error.UnexpectedError;
            },
            '\t', ' ' => {},
            '\n' => self.line += 1,
        }
    }

    // MainLoop:
    // 	for iChar, char := range s.Source {
    // 		s.Icurr = uint(iChar)
    //
    // 		if char == NEW_LINE.char1() {
    // 			s.Line++
    // 		}
    // 		if s.SkipChar {
    // 			s.SkipChar = false
    // 			continue
    // 		}
    // 		if s.SkipNext > 0 {
    // 			for s.SkipNext != 0 {
    // 				s.SkipNext--
    // 				continue MainLoop
    // 			}
    // 		}
    //
    // 		switch {
    // 		case char == EQUAL.char1():
    // 			if EQUAL_EQUAL.char2() >= 0 && s.peek() == EQUAL_EQUAL.char2() {
    // 				s.TokenList.append(Token{EQUAL_EQUAL, EQUAL_EQUAL.Literal, NULL, s.Line})
    // 				s.SkipChar = true
    // 				continue
    // 			}
    // 			s.TokenList.append(Token{EQUAL, EQUAL.Literal, NULL, s.Line})
    // 			break
    //
    // 		case char == BANG.char1():
    // 			if BANG_EQUAL.char2() >= 0 && s.peek() == BANG_EQUAL.char2() {
    // 				s.TokenList.append(Token{BANG_EQUAL, BANG_EQUAL.Literal, NULL, s.Line})
    // 				s.SkipChar = true
    // 				continue
    // 			}
    // 			s.TokenList.append(Token{BANG, BANG.Literal, NULL, s.Line})
    // 			break
    //
    // 		case char == LESS.char1():
    // 			if LESS_EQUAL.char2() >= 0 && s.peek() == LESS_EQUAL.char2() {
    // 				s.TokenList.append(Token{LESS_EQUAL, LESS_EQUAL.Literal, NULL, s.Line})
    // 				s.SkipChar = true
    // 				continue
    // 			}
    // 			s.TokenList.append(Token{LESS, LESS.Literal, NULL, s.Line})
    // 			break
    //
    // 		case char == GREATER.char1():
    // 			if GREATER_EQUAL.char2() >= 0 && s.peek() == GREATER_EQUAL.char2() {
    // 				s.TokenList.append(Token{GREATER_EQUAL, GREATER_EQUAL.Literal, NULL, s.Line})
    // 				s.SkipChar = true
    // 				continue
    // 			}
    // 			s.TokenList.append(Token{GREATER, GREATER.Literal, NULL, s.Line})
    // 			break
    //
    // 		case char == SLASH.char1():
    // 			if COMMENT.char2() >= 0 && s.peek() == COMMENT.char2() {
    // 			SkipTillNL:
    // 				for _, r := range s.Source[iChar:] {
    // 					switch r {
    // 					case NEW_LINE.char1():
    // 						break SkipTillNL
    // 					default:
    // 						s.SkipNext++
    // 						break
    // 					}
    // 				}
    // 				continue
    // 			}
    // 			s.TokenList.append(Token{SLASH, SLASH.Literal, NULL, s.Line})
    // 			break
    //
    // 		case char == TAB.char1() || char == SPACE.char1() || char == NEW_LINE.char1():
    // 			// t = &Token{TAB, TAB.Literal, NULL}
    // 			break
    //
    // 		case char == DOUBLE_QUOTE.char1():
    // 			t := new(Token)
    // 			t.Type = STRING
    // 			var buf bytes.Buffer
    // 			var i = iChar + 1
    // 			for ; i < len(s.Source) && rune(s.Source[i]) != DOUBLE_QUOTE.char1(); i++ {
    // 				r := rune(s.Source[i])
    // 				buf.WriteRune(r)
    // 				s.SkipNext++
    // 			}
    // 			s.SkipNext++
    // 			if i >= len(s.Source) {
    // 				println("[line %d] Error: Unterminated string.", s.Line)
    // 				s.UnexpectedCharError = true
    // 				break
    // 			}
    // 			t.Lexeme = buf.String()
    // 			t.Literal = buf.String()
    // 			s.TokenList.append(*t)
    // 			break
    //
    // 		case unicode.IsDigit(char):
    // 			var buf bytes.Buffer
    // 			var decimalEncountered = false
    //
    // 			buf.WriteRune(char)
    // 			var i = iChar + 1
    // 		NumberCapture:
    // 			for ; i < len(s.Source) && (unicode.IsDigit(rune(s.Source[i])) || rune(s.Source[i]) == DOT.char1()); i++ {
    // 				r := rune(s.Source[i])
    // 				if r == DOT.char1() {
    // 					if decimalEncountered {
    // 						break NumberCapture
    // 					}
    // 					decimalEncountered = true
    // 					s.SkipNext++
    // 					buf.WriteRune(r)
    // 					continue
    // 				}
    // 				s.SkipNext++
    // 				buf.WriteRune(r)
    // 			}
    // 			s.TokenList.append(Token{NUMBER, buf.String(), buf.String(), s.Line})
    // 			break
    //
    // 		case isAlpha(char):
    // 			t := new(Token)
    // 			var buf bytes.Buffer
    // 			buf.WriteRune(char)
    // 			var i = iChar + 1
    // 			for ; i < len(s.Source) && rune(s.Source[i]) != SPACE.char1() && (isAlpha(rune(s.Source[i])) || unicode.IsDigit(rune(s.Source[i]))); i++ {
    // 				r := rune(s.Source[i])
    // 				buf.WriteRune(r)
    // 				s.SkipNext++
    // 			}
    // 			switch buf.String() {
    // 			case AND.Literal:
    // 				t = &Token{AND, AND.Literal, NULL, s.Line}
    // 				break
    // 			case CLASS.Literal:
    // 				t = &Token{CLASS, CLASS.Literal, NULL, s.Line}
    // 				break
    // 			case ELSE.Literal:
    // 				t = &Token{ELSE, ELSE.Literal, NULL, s.Line}
    // 				break
    // 			case FALSE.Literal:
    // 				t = &Token{FALSE, FALSE.Literal, NULL, s.Line}
    // 				break
    // 			case FOR.Literal:
    // 				t = &Token{FOR, FOR.Literal, NULL, s.Line}
    // 				break
    // 			case FUN.Literal:
    // 				t = &Token{FUN, FUN.Literal, NULL, s.Line}
    // 				break
    // 			case IF.Literal:
    // 				t = &Token{IF, IF.Literal, NULL, s.Line}
    // 				break
    // 			case NIL.Literal:
    // 				t = &Token{NIL, NIL.Literal, NULL, s.Line}
    // 				break
    // 			case OR.Literal:
    // 				t = &Token{OR, OR.Literal, NULL, s.Line}
    // 				break
    // 			case PRINT.Literal:
    // 				t = &Token{PRINT, PRINT.Literal, NULL, s.Line}
    // 				break
    // 			case RETURN.Literal:
    // 				t = &Token{RETURN, RETURN.Literal, NULL, s.Line}
    // 				break
    // 			case SUPER.Literal:
    // 				t = &Token{SUPER, SUPER.Literal, NULL, s.Line}
    // 				break
    // 			case THIS.Literal:
    // 				t = &Token{THIS, THIS.Literal, NULL, s.Line}
    // 				break
    // 			case TRUE.Literal:
    // 				t = &Token{TRUE, TRUE.Literal, NULL, s.Line}
    // 				break
    // 			case VAR.Literal:
    // 				t = &Token{VAR, VAR.Literal, NULL, s.Line}
    // 				break
    // 			case WHILE.Literal:
    // 				t = &Token{WHILE, WHILE.Literal, NULL, s.Line}
    // 				break
    // 			default:
    // 				t = &Token{IDENTIFIER, buf.String(), NULL, s.Line}
    // 				break
    // 			}
    // 			s.TokenList.append(*t)
    // 			break
    //
    // 		default:
    // 			println("[line %d] Error: Unexpected character: %c", s.Line, char)
    // 			s.UnexpectedCharError = true
    // 			break
    // 		}
    // 	}
    //
    // 	s.TokenList.append(Token{EOF, EOF.Literal, NULL, s.Line})
    try self.tokenList.append(Token.New(TokenType.EOF, "", Literal.None()));
}
