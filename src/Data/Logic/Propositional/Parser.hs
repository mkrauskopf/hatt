{-# OPTIONS_GHC -fno-warn-unused-do-bind #-}
{-# OPTIONS_HADDOCK hide #-}

module Data.Logic.Propositional.Parser
    ( parseExpr
    ) where

import Data.Logic.Propositional.Core (Expr (..))

import Text.ParserCombinators.Parsec
    (char, choice, eof, oneOf, parse, spaces, string)

import Text.ParserCombinators.Parsec.Error (ParseError)
import Text.ParserCombinators.Parsec.Pos (SourceName)
import Text.ParserCombinators.Parsec.Prim (GenParser)

-- | The 'parseExpr' function accepts the name of a source, and a string to be
-- parsed, and attempts to parse the string as a logical expression of the
-- following forms, where @&#966;@ and @&#968;@ are metalinguistic variables
-- standing for any valid expression.
--
-- * Variables: @\"P\"@, @\"Q\"@, @\"R\"@ etc.; basically anything in the
--   character class @[A-Z]@
--
-- * Negation: @\"~&#966;\"@
--
-- * Conjunction: @\"(&#966; & &#968;)\"@
--
-- * Disjunction: @\"(&#966; | &#968;)\"@
--
-- * Conditional: @\"(&#966; -> &#968;)\"@
--
-- * Biconditional: @\"(&#966; \<-> &#968;)\"@
parseExpr :: SourceName -> String -> Either ParseError Expr
parseExpr = parse statement

statement :: GenParser Char st Expr
statement = do spaces
               x <- expr
               spaces
               eof
               return x

expr :: GenParser Char st Expr
expr = choice [binaryP, negation, variable]

variable :: GenParser Char st Expr
variable = do c <- oneOf ['A'..'Z']
              return $ Variable [c]

negation :: GenParser Char st Expr
negation = do char '~'
              x <- expr
              return $ Negation x

binaryP :: GenParser Char st Expr
binaryP = do char '('
             x <- binary
             char ')'
             return x

binary :: GenParser Char st Expr
binary = do x1 <- expr
            spaces
            s  <- choice [string "&", string "|", string "->", string "<->"]
            spaces
            x2 <- expr
            return $ connective s x1 x2
  where
    connective "&"   = Conjunction
    connective "|"   = Disjunction
    connective "->"  = Conditional
    connective "<->" = Biconditional
    connective _     = error "Impossible case"