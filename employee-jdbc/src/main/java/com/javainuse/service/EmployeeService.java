package com.javainuse.service;

import java.util.List;

import com.javainuse.model.Employee;

public interface EmployeeService {
	List<Employee> getAllEmployees();
	void insertEmployee(Employee employee);
}