/**
 * Copyright (c) 2017 committers of YAKINDU and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 * 	Andreas Muelder - Itemis AG - initial API and implementation
 * 	Karsten Thoms   - Itemis AG - initial API and implementation
 * 	Florian Antony  - Itemis AG - initial API and implementation
 * 	committers of YAKINDU 
 * 
 */
package com.yakindu.solidity.typesystem

import com.google.inject.Inject
import com.yakindu.solidity.solidity.AddressLiteral
import com.yakindu.solidity.solidity.DecimalNumberLiteral
import com.yakindu.solidity.solidity.FunctionDefinition
import com.yakindu.solidity.solidity.NewInstanceExpression
import com.yakindu.solidity.solidity.NumericalMultiplyDivideExpression
import com.yakindu.solidity.solidity.VariableDefinition
import java.math.BigDecimal
import org.eclipse.emf.ecore.EObject
import org.yakindu.base.expressions.expressions.BoolLiteral
import org.yakindu.base.expressions.expressions.ElementReferenceExpression
import org.yakindu.base.expressions.expressions.FeatureCall
import org.yakindu.base.expressions.inferrer.ExpressionsTypeInferrer
import org.yakindu.base.types.Type
import org.yakindu.base.types.TypedElement
import org.yakindu.base.types.typesystem.ITypeSystem

import static org.yakindu.base.types.typesystem.ITypeSystem.REAL

/**
 * 
 * @author andreas muelder - Initial contribution and API
 * @author Florian Antony
 * 
 */
class SolidityTypeInferrer extends ExpressionsTypeInferrer {

	@Inject protected ITypeSystem ts;

	def doInfer(EObject e) {
		null
	}

	def doInfer(BigDecimal literal) {
		InferenceResult.from(ts.getType(SolidityTypeSystem.INTEGER));
	}

	def doInfer(AddressLiteral literal) {
		InferenceResult.from(ts.getType(SolidityTypeSystem.ADDRESS));
	}

	def doInfer(DecimalNumberLiteral literal) {
		return getResultFor(SolidityTypeSystem.INTEGER);
	}
	
	def doInfer(NewInstanceExpression it){
		inferTypeDispatch(type)
	}
 
	override assertAssignable(InferenceResult varResult, InferenceResult valueResult, String msg) {
		if (ts.isSame(valueResult.type, ts.getType(ITypeSystem.INTEGER)) &&
			ts.isSuperType(varResult.type, ts.getType(ITypeSystem.INTEGER))) {
			return;
		}
		assertCompatible(varResult, valueResult, msg)
	}

	override protected assertCompatible(InferenceResult result1, InferenceResult result2, String msg) {
		if (result1.type == ts.getType(ITypeSystem.ANY) || result2.type == ts.getType(ITypeSystem.ANY))
			return;
		super.assertCompatible(result1, result2, msg);
	}

	override doInfer(BoolLiteral literal) {
		InferenceResult.from(ts.getType(SolidityTypeSystem.BOOL))
	}

	def doInfer(NumericalMultiplyDivideExpression e) {
		var result1 = inferTypeDispatch(e.getLeftOperand())
		var result2 = inferTypeDispatch(e.getRightOperand())
		assertCompatible(result1, result2, String.format(ARITHMETIC_OPERATORS, e.getOperator(), result1, result2))
		assertIsSubType(result1, getResultFor(REAL),
			String.format(ARITHMETIC_OPERATORS, e.getOperator(), result1, result2))
		getCommonType(result1, result2)
	}

	// Type Cast	
	override doInfer(ElementReferenceExpression e) {
		if (e.isOperationCall() && (e.reference instanceof Type)) {
			return inferTypeDispatch(e.reference)
		}
		return super.doInfer(e)
	}

	// Type Cast	
	override doInfer(FeatureCall e) {
		if (e.isOperationCall() && (e.feature instanceof TypedElement)) {
			return inferTypeDispatch(e.feature)
		}
		return super.doInfer(e)
	}

	def doInfer(FunctionDefinition op) {
		if (op.returnParameters.size == 0 && op.typeSpecifier === null)
			getResultFor(ITypeSystem.VOID)
		else if (op.typeSpecifier !== null)
			return inferTypeDispatch(op.typeSpecifier.type)
		else
			inferTypeDispatch(op.returnParameters.head);
	}

	override protected getResultFor(String name) {
		if (ITypeSystem.BOOLEAN.equals(name))
			return super.getResultFor(SolidityTypeSystem.BOOL)
		else
			return super.getResultFor(name)
	}

	def doInfer(VariableDefinition definition) {
		if (definition.typeSpecifier !== null)
			return inferTypeDispatch(definition.typeSpecifier)
		return doInfer(definition.initialValue)
	}
}
