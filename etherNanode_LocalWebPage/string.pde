
//-----------------------------------------------------------------------------------------------
// Converts a double in to a string
//-----------------------------------------------------------------------------------------------
char * doubleString(double value, int precision )
{
   char intPartStr[20];
   char decPartStr[20];
   char doubleStr[20] = "";
   
   if (value<0) 
   {
     value=value*-1;
     strcat(doubleStr, "-");     
   }
   
   int intPart = (int)value;
      
   double decPart = (value-intPart)*(pow(10,precision));

   itoa(intPart, intPartStr, 10);
   itoa((int)decPart, decPartStr, 10);
   
   strcat(doubleStr, intPartStr);   
   strcat(doubleStr, ".");
   strcat(doubleStr, decPartStr);
   return doubleStr;
}
