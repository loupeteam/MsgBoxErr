(*
 * File: MsgBoxAck.st
 * Copyright (c) 2023 Loupe
 * https://loupe.team
 * 
 * This file is part of MsgBoxErr, licensed under the MIT License.
 *)

(* This function block will post a message block that can be acknowledged or add to the error collector *)
FUNCTION_BLOCK MsgBoxAck

	IF AckError THEN
		AckError:= FALSE;
		Accept:=	FALSE;
		Ignored:=	FALSE;
		ErrorTimeout.IN:=	TRUE;
	END_IF	
	
	//Give an acknowledge error some time to clear
	ErrorTimeout.PT:=	T#1s;
	ErrorTimeout();
	IF ErrorTimeout.Q THEN
		ErrorTimeout.IN:=	FALSE;
		ErrorAdded:= FALSE;				
	END_IF	
	
	Execute:= 	FALSE;

	
	IF Active
		AND MsgID = 0		
		AND NOT Ignored
		THEN

		OkAddr:=0;
		IgnoreAddr:=0;
	
		IF OKText <> '' THEN
			OkAddr:=ADR(OKText);
			OkCmd:=ADR(Accept);
		END_IF	
		IF IgnoreText <> '' THEN
			IgnoreAddr:=ADR(IgnoreText);	
			IgnoreCmd:=	ADR(Ignored);
		END_IF	

		IF Password = '' THEN
			MsgID:= MessageBox_AddMsg(ADR(Message),OkAddr,OkCmd,IgnoreAddr,IgnoreCmd);
		ELSE
			InputPassword:='';
			MsgID:= PromptBox_AddMsg(ADR(Message),ADR(InputPassword),OkAddr,OkCmd,IgnoreAddr,IgnoreCmd);			
		END_IF	
	ELSIF NOT Active THEN
		Ignored:=0;
		Accept:=0;
	END_IF
	
	IF MsgID <> 0 
		AND (NOT Active OR Ignored)
		THEN
		MessageBox_RemoveMsg(MsgID);		
		MsgID:=	0;		
	END_IF	
	
	IF (Password <> '' AND Ignored) OR (IsError AND Active)
		THEN
		IF NOT ErrorAdded THEN
			IF pErrCol <> 0 THEN
				dErrcol ACCESS pErrCol;
				addstatus:=errcolAddError(ADR(''),ADR(Message),1,ADR(AckError),dErrcol);
				IF addstatus = 0 OR addstatus = 58202 THEN
					ErrorAdded:= TRUE;
				END_IF	
			END_IF	
		END_IF	
	END_IF	
	
	IF Accept THEN
		MsgID:=		0;
		Accept:=	0;
		Ignored:=	0;
		IF Password <> '' THEN
			IF Password = InputPassword THEN
				Execute:= 	TRUE;
			ELSE
				Ignored:= TRUE;				
			END_IF	
		ELSE
			Execute:= 	TRUE;			
		END_IF	
	END_IF
	
	
END_FUNCTION_BLOCK